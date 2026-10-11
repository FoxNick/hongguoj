package core

import (
	"bytes"
	"context"
	"crypto/aes"
	"crypto/cipher"
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type cencSource struct {
	stream  *nativeStreamServer
	session *nativeStreamSession
	asset   nativeStreamAsset
	ctx     context.Context
	total   int64
	etag    string
}
type cencBody struct {
	io.Reader
	closer io.Closer
}

func (body cencBody) Close() error { return body.closer.Close() }

func (source *cencSource) open(offset, length int64) (io.ReadCloser, error) {
	if err := source.ctx.Err(); err != nil {
		return nil, err
	}
	local := source.asset.file
	if local == "" && filepath.IsAbs(source.asset.address) {
		local = source.asset.address
	}
	if local != "" {
		file, err := os.Open(local)
		if err != nil {
			return nil, err
		}
		info, err := file.Stat()
		if err != nil || !info.Mode().IsRegular() {
			file.Close()
			return nil, errCENCFormat
		}
		if source.total != 0 && source.total != info.Size() {
			file.Close()
			return nil, errors.New("本地媒体在播放期间发生变化")
		}
		source.total = info.Size()
		if offset < 0 || offset > source.total {
			file.Close()
			return nil, errCENCFormat
		}
		if _, err = file.Seek(offset, io.SeekStart); err != nil {
			file.Close()
			return nil, err
		}
		return cencBody{io.LimitReader(file, min(length, source.total-offset)), file}, nil
	}
	asset := source.asset
	cacheEnd := int64(len(asset.data))
	complete := cacheEnd == asset.total
	validated := asset.etag != "" && !strings.HasPrefix(asset.etag, "W/")
	if offset >= 0 && length > 0 && offset < cacheEnd && asset.total >= cacheEnd &&
		(complete || validated) && (source.total == 0 || source.total == asset.total) &&
		(source.etag == "" || source.etag == asset.etag) {
		source.total, source.etag = asset.total, asset.etag
		end := min(offset+length, source.total)
		prefixEnd := min(end, cacheEnd)
		prefix := bytes.NewReader(asset.data[offset:prefixEnd])
		if prefixEnd == end {
			return io.NopCloser(prefix), nil
		}
		return &cencPrefetchedBody{prefix: prefix, source: source, offset: prefixEnd, length: end - prefixEnd}, nil
	}
	request, err := http.NewRequestWithContext(source.ctx, http.MethodGet, source.asset.address, nil)
	if err != nil {
		return nil, err
	}
	request.Header.Set("Referer", source.session.referer)
	request.Header.Set("Range", fmt.Sprintf("bytes=%d-%d", offset, offset+length-1))
	if source.etag != "" && !strings.HasPrefix(source.etag, "W/") {
		request.Header.Set("If-Match", source.etag)
	}
	response, err := source.stream.nativeRequest(request)
	if err != nil {
		return nil, err
	}
	start, end, total, valid := nativeContentRange(response.Header.Get("Content-Range"))
	prefetched := cacheEnd > 0 && cacheEnd < asset.total && validated && source.etag == asset.etag
	if response.StatusCode != http.StatusPartialContent || !valid || start != offset || end != min(offset+length, total)-1 || source.total != 0 && source.total != total || source.etag != "" && response.Header.Get("ETag") != "" && response.Header.Get("ETag") != source.etag || prefetched && response.Header.Get("ETag") != asset.etag {
		response.Body.Close()
		return nil, fmt.Errorf("加密媒体 Range 响应异常（HTTP %d）", response.StatusCode)
	}
	source.total = total
	if source.etag == "" {
		source.etag = response.Header.Get("ETag")
	}
	return response.Body, nil
}

type cencPrefetchedBody struct {
	prefix         *bytes.Reader
	source         *cencSource
	offset, length int64
	upstream       io.ReadCloser
	closed         bool
}

func (body *cencPrefetchedBody) Read(data []byte) (int, error) {
	if body.closed {
		return 0, io.ErrClosedPipe
	}
	if len(data) == 0 {
		return 0, nil
	}
	if body.prefix.Len() > 0 {
		return body.prefix.Read(data)
	}
	if body.upstream == nil {
		upstream, err := body.source.open(body.offset, body.length)
		if err != nil {
			return 0, err
		}
		body.upstream = upstream
	}
	return body.upstream.Read(data)
}

func (body *cencPrefetchedBody) Close() error {
	body.closed = true
	if body.upstream != nil {
		return body.upstream.Close()
	}
	return nil
}
func (source *cencSource) bytes(offset, length int64) ([]byte, error) {
	if length < 1 || length > cencMetadataLimit {
		return nil, errCENCFormat
	}
	body, err := source.open(offset, length)
	if err != nil {
		return nil, err
	}
	defer body.Close()
	data, err := io.ReadAll(io.LimitReader(body, length))
	if err != nil {
		return nil, err
	}
	if int64(len(data)) != min(length, source.total-offset) {
		return nil, io.ErrUnexpectedEOF
	}
	return data, nil
}
func (source *cencSource) index() (*cencIndex, error) {
	prefix, err := source.bytes(0, 64<<10)
	if err != nil {
		return nil, err
	}
	if source.total < 8 || source.total > 64<<30 {
		return nil, errCENCFormat
	}
	for offset, boxes := int64(0), 0; offset < source.total && boxes < 256; boxes++ {
		var header []byte
		if offset+16 <= int64(len(prefix)) {
			header = prefix[offset : offset+16]
		} else {
			header, err = source.bytes(offset, 16)
			if err != nil {
				return nil, err
			}
		}
		if len(header) < 8 {
			return nil, errCENCFormat
		}
		size := uint64(binary.BigEndian.Uint32(header))
		headerSize := uint64(8)
		if size == 1 {
			if len(header) < 16 {
				return nil, errCENCFormat
			}
			size = binary.BigEndian.Uint64(header[8:])
			headerSize = 16
		}
		if size == 0 {
			size = uint64(source.total - offset)
		}
		if size < headerSize || size > uint64(source.total-offset) {
			return nil, errCENCFormat
		}
		switch string(header[4:8]) {
		case "moof":
			return nil, fmt.Errorf("%w：分片 MP4", errCENCFormat)
		case "moov":
			if size > cencMetadataLimit {
				return nil, errCENCFormat
			}
			var metadata []byte
			if offset+int64(size) <= int64(len(prefix)) {
				metadata = prefix[offset : offset+int64(size)]
			} else {
				metadata, err = source.bytes(offset, int64(size))
				if err != nil {
					return nil, err
				}
			}
			index, err := parseCENCMP4(metadata, offset, source.total)
			if err != nil {
				return nil, err
			}
			index.etag = source.etag
			return index, nil
		}
		offset += int64(size)
	}
	return nil, errCENCFormat
}

type cencReadSeeker struct {
	source   *cencSource
	index    *cencIndex
	block    cipher.Block
	body     io.ReadCloser
	position int64
}

func (reader *cencReadSeeker) Read(data []byte) (int, error) {
	if len(data) == 0 {
		return 0, nil
	}
	if reader.position >= reader.index.total {
		return 0, io.EOF
	}
	if reader.body == nil {
		body, err := reader.source.open(reader.position, reader.index.total-reader.position)
		if err != nil {
			return 0, err
		}
		reader.body = body
	}
	n, err := reader.body.Read(data)
	if n > 0 {
		reader.index.transform(data[:n], reader.position, reader.block)
		reader.position += int64(n)
	}
	return n, err
}
func (reader *cencReadSeeker) Seek(offset int64, whence int) (int64, error) {
	var target int64
	switch whence {
	case io.SeekStart:
		target = offset
	case io.SeekCurrent:
		target = reader.position + offset
	case io.SeekEnd:
		target = reader.index.total + offset
	default:
		return 0, errCENCFormat
	}
	if target < 0 || target > reader.index.total {
		return 0, errCENCFormat
	}
	if target != reader.position {
		reader.Close()
		reader.position = target
	}
	return target, nil
}
func (reader *cencReadSeeker) Close() error {
	if reader.body != nil {
		err := reader.body.Close()
		reader.body = nil
		return err
	}
	return nil
}

func (stream *nativeStreamServer) nativeCENCIndex(ctx context.Context, session *nativeStreamSession, asset nativeStreamAsset) (*cencIndex, error) {
	session.cencMu.Lock()
	defer session.cencMu.Unlock()
	index := session.cenc
	var err error
	if index == nil {
		metadataContext, cancel := context.WithTimeout(ctx, 30*time.Second)
		source := &cencSource{stream: stream, session: session, asset: asset, ctx: metadataContext}
		index, err = source.index()
		cancel()
		if err == nil {
			session.cenc = index
		}
	}
	return index, err
}

func (stream *nativeStreamServer) nativeServeCENC(writer http.ResponseWriter, request *http.Request, session *nativeStreamSession, asset nativeStreamAsset, ctx context.Context) {
	if len(session.cencKey) != aes.BlockSize {
		http.Error(writer, "播放会话没有有效媒体密钥", http.StatusUnprocessableEntity)
		return
	}
	index, err := stream.nativeCENCIndex(ctx, session, asset)
	if err != nil {
		http.Error(writer, "MP4 解密准备失败："+publicError(err).Error(), http.StatusUnprocessableEntity)
		return
	}
	block, err := aes.NewCipher(session.cencKey)
	if err != nil {
		http.Error(writer, "媒体密钥无效", http.StatusUnprocessableEntity)
		return
	}
	source := &cencSource{stream: stream, session: session, asset: asset, ctx: ctx, total: index.total, etag: index.etag}
	reader := &cencReadSeeker{source: source, index: index, block: block}
	defer reader.Close()
	writer.Header().Set("Content-Type", "video/mp4")
	writer.Header().Set("X-Hongguo-Media", "clear-cenc-mp4")
	http.ServeContent(writer, request, "video.mp4", time.Time{}, reader)
}
