package core

import (
	"context"
	"crypto/aes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

type nativeDownloadAsset struct {
	address string
	name    string
	data    []byte
	key     bool
}

type nativeDownloadBundle struct {
	assets    []nativeDownloadAsset
	playlists map[string][]byte
	quality   int
	startup   map[string]bool
	sources   []nativeStartupPlaylist
}

type nativeDownloadFileState struct {
	URL       string `json:"url"`
	Validator string `json:"validator"`
	Total     int64  `json:"total"`
	Complete  bool   `json:"complete"`
}

type nativeDownloadHLSKey struct{}

func (manager *nativeDownloads) transferMedia(ctx context.Context, job nativeDownloadJob, media providerMedia) (nativeDownloadResult, error) {
	ctx = providerMediaContext(ctx, media.credentials)
	bundle := nativeDownloadBundle{quality: media.Quality, playlists: map[string][]byte{}}
	parsed, err := url.Parse(media.URL)
	if err != nil || !isProviderHTTPMediaURL(media.URL) {
		return nativeDownloadResult{}, errors.New("下载地址无效")
	}
	hls := media.Playlist != "" || len(media.HLSKey) > 0 || ctx.Value(nativeDownloadHLSKey{}) == true || strings.HasSuffix(strings.ToLower(parsed.Path), ".m3u8")
	entry := nativeDownloadFileName(job.Drama, job.Index, ".mp4")
	if hls {
		entry = nativeDownloadFileName(job.Drama, job.Index, ".m3u8")
		bundle, err = manager.downloadBundle(ctx, media, job.Quality, entry)
		if err != nil {
			return nativeDownloadResult{}, err
		}
	} else {
		bundle.assets = []nativeDownloadAsset{{address: media.URL, name: entry}}
	}
	if cache := nativeStartupCache(ctx); cache != nil {
		cache.prepareStartup(&bundle, hls)
	}
	directory := manager.jobDirectory(job)
	identity := entry + "\x00" + media.URL + "\x00" + hex.EncodeToString(media.CENCKey) + "\x00" + strconv.Itoa(bundle.quality)
	if hls {
		for _, asset := range bundle.assets {
			identity += "\x00" + asset.address + "\x00" + string(asset.data)
		}
		encoded, _ := json.Marshal(bundle.playlists)
		identity += "\x00" + string(encoded)
	}
	sum := sha256.Sum256([]byte(identity))
	fingerprint := hex.EncodeToString(sum[:])
	marker := filepath.Join(nativeDownloadMetaDirectory(directory), nativeDownloadMarkerName(job))
	if err := os.MkdirAll(directory, 0700); err != nil {
		return nativeDownloadResult{}, errors.New("无法创建下载文件，请检查存储空间")
	}
	names := []string{entry}
	for _, asset := range bundle.assets {
		names = append(names, asset.name)
	}
	for name := range bundle.playlists {
		names = append(names, name)
	}
	if previous, readErr := os.ReadFile(marker); readErr == nil {
		var saved nativeDownloadMarker
		if json.Unmarshal(previous, &saved) == nil && saved.Fingerprint != fingerprint {
			for _, name := range saved.Files {
				discardDownloadMedia(directory, name)
			}
		}
	}
	encoded, encodeErr := json.Marshal(nativeDownloadMarker{Fingerprint: fingerprint, Files: names})
	if encodeErr != nil {
		return nativeDownloadResult{}, errors.New("无法记录下载计划")
	}
	if err := nativeDownloadWrite(marker, encoded); err != nil {
		return nativeDownloadResult{}, err
	}
	var completedBytes int64
	for index, asset := range bundle.assets {
		if err := ctx.Err(); err != nil {
			return nativeDownloadResult{}, err
		}
		target := filepath.Join(directory, asset.name)
		var size int64
		if asset.data != nil {
			err = nativeDownloadWrite(target, asset.data)
			size = int64(len(asset.data))
			if err == nil {
				if cache := nativeStartupCache(ctx); cache != nil {
					cache.publishStartup(nativeStreamAsset{address: asset.address, data: asset.data, total: size, contentType: "application/octet-stream"}, true, asset.key)
				}
			}
		} else {
			size, err = manager.downloadFile(ctx, asset.address, media.Referer, target, asset.key, func(received, total int64) {
				progress := 0.0
				if total > 0 {
					progress = min(1, float64(received)/float64(total))
				}
				if hls {
					progress = (float64(index) + progress) / float64(len(bundle.assets))
				}
				overallTotal := int64(0)
				if !hls {
					overallTotal = total
				}
				manager.progress(job.ID, completedBytes+received, overallTotal, progress)
			})
		}
		if err != nil {
			return nativeDownloadResult{}, err
		}
		completedBytes += size
		manager.progress(job.ID, completedBytes, 0, float64(index+1)/float64(len(bundle.assets)))
	}
	if err := ctx.Err(); err != nil {
		return nativeDownloadResult{}, err
	}
	candidates, decrypted := 0, 0
	if len(media.CENCKey) == aes.BlockSize {
		for _, asset := range bundle.assets {
			if asset.data != nil || !nativeDownloadCENCMedia(asset.name) {
				continue
			}
			candidates++
			ok, err := nativeDecryptDownloadedCENC(filepath.Join(directory, asset.name), media.CENCKey)
			if err != nil {
				return nativeDownloadResult{}, err
			}
			if ok {
				decrypted++
			}
		}
	}
	for name, body := range bundle.playlists {
		if err := nativeDownloadWrite(filepath.Join(directory, name), body); err != nil {
			return nativeDownloadResult{}, err
		}
	}
	manager.progress(job.ID, completedBytes, completedBytes, 1)
	key := hex.EncodeToString(media.CENCKey)
	if candidates > 0 && candidates == decrypted {
		key = ""
	}
	return nativeDownloadResult{file: entry, key: key, quality: bundle.quality}, nil
}

func nativeDownloadValidator(header http.Header) string {
	if value := header.Get("ETag"); value != "" && !strings.HasPrefix(value, "W/") {
		return value
	}
	if value := header.Get("Last-Modified"); value != "" {
		if _, err := http.ParseTime(value); err == nil {
			return value
		}
	}
	return ""
}

func nativeDownloadRange(value string) (int64, int64, int64, bool) {
	var start, end, total int64
	if count, err := fmt.Sscanf(value, "bytes %d-%d/%d", &start, &end, &total); err != nil || count != 3 {
		return 0, 0, 0, false
	}
	return start, end, total, start >= 0 && end >= start && total > end
}

const nativeDownloadMetaDir = ".meta"

func nativeDownloadMetaDirectory(directory string) string {
	return filepath.Join(directory, nativeDownloadMetaDir)
}

func nativeDownloadMetaPath(target string) string {
	return filepath.Join(nativeDownloadMetaDirectory(filepath.Dir(target)), filepath.Base(target)+".json")
}

func nativeDownloadMetaRead(target string) ([]byte, error) {
	data, err := os.ReadFile(nativeDownloadMetaPath(target))
	if err == nil || !os.IsNotExist(err) {
		return data, err
	}
	return os.ReadFile(target + ".json")
}

func (manager *nativeDownloads) downloadFile(ctx context.Context, address, referer, target string, key bool, progress func(int64, int64)) (int64, error) {
	var metadata nativeDownloadFileState
	if data, err := nativeDownloadMetaRead(target); err == nil {
		_ = json.Unmarshal(data, &metadata)
	}
	if metadata.URL != address {
		metadata = nativeDownloadFileState{}
	}
	if metadata.Complete {
		if info, err := os.Stat(target); err == nil && info.Size() == metadata.Total && info.Size() > 0 && (!key || info.Size() == 16) {
			progress(info.Size(), info.Size())
			if cache := nativeStartupCache(ctx); cache != nil {
				header := http.Header{}
				if strings.HasPrefix(metadata.Validator, "\"") {
					header.Set("ETag", metadata.Validator)
				} else {
					header.Set("Last-Modified", metadata.Validator)
				}
				cache.publishStartupFile(address, target, metadata, header, info.Size(), true, key)
			}
			return info.Size(), nil
		}
	}
	partial := target + ".part"
	offset := int64(0)
	if metadata.Validator != "" && !key {
		if info, err := os.Stat(partial); err == nil && info.Size() > 0 && (metadata.Total <= 0 || info.Size() <= metadata.Total) {
			offset = info.Size()
		}
	}
	for attempt := 0; attempt < 2; attempt++ {
		size, restart, err := manager.downloadFileAttempt(ctx, address, referer, target, key, offset, metadata, progress)
		if !restart {
			return size, err
		}
		offset, metadata = 0, nativeDownloadFileState{}
	}
	return 0, errors.New("服务器无法恢复下载，请重试")
}

func (manager *nativeDownloads) downloadFileAttempt(ctx context.Context, address, referer, target string, key bool, offset int64, old nativeDownloadFileState, progress func(int64, int64)) (int64, bool, error) {
	if !isProviderHTTPMediaURL(address) {
		return 0, false, errors.New("媒体下载地址无效")
	}
	requestCtx, cancel := context.WithCancel(ctx)
	defer cancel()
	inactivity := time.AfterFunc(30*time.Second, cancel)
	defer inactivity.Stop()
	request, err := http.NewRequestWithContext(requestCtx, http.MethodGet, address, nil)
	if err != nil {
		return 0, false, err
	}
	request.Header.Set("User-Agent", userAgent)
	request.Header.Set("Referer", referer)
	request.Header.Set("Accept-Encoding", "identity")
	if offset > 0 {
		request.Header.Set("Range", fmt.Sprintf("bytes=%d-", offset))
		request.Header.Set("If-Range", old.Validator)
	}
	client := *manager.engine.downloader.client
	client.Timeout = 0
	response, err := manager.engine.downloader.doMediaRequestWithClient(request, &client)
	if err != nil {
		return 0, false, errors.New("下载连接中断，请检查网络后继续")
	}
	defer response.Body.Close()
	if offset > 0 && (response.StatusCode == http.StatusRequestedRangeNotSatisfiable || response.StatusCode == http.StatusPreconditionFailed) {
		return 0, true, nil
	}
	if response.StatusCode != http.StatusOK && response.StatusCode != http.StatusPartialContent {
		return 0, false, nativeDownloadError(response.StatusCode)
	}
	if response.StatusCode == http.StatusOK {
		offset = 0
	}
	if encoding := response.Header.Get("Content-Encoding"); encoding != "" && encoding != "identity" {
		return 0, false, errors.New("服务器返回了压缩媒体响应，无法安全续传")
	}
	contentType := strings.ToLower(response.Header.Get("Content-Type"))
	if !key && (strings.Contains(contentType, "text/html") || strings.Contains(contentType, "application/json")) {
		return 0, false, errors.New("站源返回了错误页面，请刷新下载地址后重试")
	}
	total := response.ContentLength
	validator := nativeDownloadValidator(response.Header)
	if response.StatusCode == http.StatusPartialContent {
		start, end, full, valid := nativeDownloadRange(response.Header.Get("Content-Range"))
		if !valid || start != offset || (response.ContentLength >= 0 && response.ContentLength != end-start+1) {
			return 0, false, errors.New("服务器返回的续传范围不正确，已停止下载")
		}
		if offset > 0 && (validator != old.Validator || (old.Total > 0 && old.Total != full)) {
			return 0, true, nil
		}
		total = full
	}
	if key && (total > 64 || offset > 0) {
		return 0, false, errors.New("视频密钥格式无效")
	}
	metadata := nativeDownloadFileState{URL: address, Validator: validator, Total: total}
	encoded, _ := json.Marshal(metadata)
	meta := nativeDownloadMetaPath(target)
	if err := os.MkdirAll(filepath.Dir(meta), 0700); err != nil {
		return 0, false, err
	}
	if err := nativeDownloadWrite(meta, encoded); err != nil {
		return 0, false, err
	}
	flags := os.O_CREATE | os.O_WRONLY
	if offset == 0 {
		flags |= os.O_TRUNC
	} else {
		flags |= os.O_APPEND
	}
	file, err := os.OpenFile(target+".part", flags, 0600)
	if err != nil {
		return 0, false, errors.New("无法写入下载文件，请检查存储空间")
	}
	received := offset
	buffer := make([]byte, 64<<10)
	for {
		n, readErr := response.Body.Read(buffer)
		if n > 0 {
			if key && received+int64(n) > 64 {
				err = errors.New("视频密钥过大")
				break
			}
			written, writeErr := file.Write(buffer[:n])
			received += int64(written)
			if writeErr != nil || written != n {
				err = errors.New("写入下载文件失败，请检查剩余空间")
				break
			}
			inactivity.Reset(30 * time.Second)
			progress(received, total)
			if cache := nativeStartupCache(ctx); cache != nil {
				cache.publishStartupFile(address, target+".part", metadata, response.Header, received, false, key)
			}
		}
		if readErr != nil {
			if readErr != io.EOF {
				err = errors.New("媒体文件未接收完整，点击继续下载")
			}
			break
		}
	}
	if err == nil {
		err = requestCtx.Err()
	}
	if err == nil && (received == 0 || (total >= 0 && received != total)) {
		err = errors.New("媒体文件未接收完整，点击继续下载")
	}
	if err == nil && key && received != 16 {
		err = errors.New("视频密钥长度无效")
	}
	if err == nil {
		err = file.Sync()
	}
	closeErr := file.Close()
	if err != nil {
		return received, false, err
	}
	if closeErr != nil {
		return received, false, closeErr
	}
	if err = os.Rename(target+".part", target); err != nil {
		return received, false, err
	}
	metadata.Complete, metadata.Total = true, received
	encoded, _ = json.Marshal(metadata)
	if err = nativeDownloadWrite(nativeDownloadMetaPath(target), encoded); err != nil {
		return received, false, err
	}
	if cache := nativeStartupCache(ctx); cache != nil {
		cache.publishStartupFile(address, target, metadata, response.Header, received, true, key)
	}
	return received, false, nil
}

func (manager *nativeDownloads) downloadPlaylist(ctx context.Context, address, referer string) (string, string, error) {
	return manager.engine.downloader.fetchMediaPlaylist(ctx, address, referer)
}
