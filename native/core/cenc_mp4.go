package core

import (
	"crypto/cipher"
	"encoding/binary"
	"errors"
	"fmt"
	"sort"
)

const cencMetadataLimit = 32 << 20
const cencSampleLimit = 500000

var errCENCFormat = errors.New("该 MP4 的加密结构暂不支持安全转发")

type cencBox struct {
	kind             string
	start, body, end int
}
type cencPatch struct {
	offset int64
	data   []byte
}
type cencSpan struct {
	start, end, counterOffset int64
	iv                        [16]byte
}
type cencIndex struct {
	etag    string
	total   int64
	patches []cencPatch
	spans   []cencSpan
}

func cencBoxes(data []byte, start, end int) ([]cencBox, error) {
	var out []cencBox
	if start < 0 || end > len(data) || start > end {
		return nil, errCENCFormat
	}
	for start < end {
		if end-start < 8 {
			return nil, errCENCFormat
		}
		size := uint64(binary.BigEndian.Uint32(data[start:]))
		header := 8
		if size == 1 {
			if end-start < 16 {
				return nil, errCENCFormat
			}
			size = binary.BigEndian.Uint64(data[start+8:])
			header = 16
		}
		if size == 0 {
			size = uint64(end - start)
		}
		if size < uint64(header) || size > uint64(end-start) {
			return nil, errCENCFormat
		}
		out = append(out, cencBox{string(data[start+4 : start+8]), start, start + header, start + int(size)})
		start += int(size)
	}
	return out, nil
}
func cencChild(data []byte, parent cencBox, kind string) (cencBox, error) {
	rows, err := cencBoxes(data, parent.body, parent.end)
	if err != nil {
		return cencBox{}, err
	}
	for _, row := range rows {
		if row.kind == kind {
			return row, nil
		}
	}
	return cencBox{}, fmt.Errorf("%w：缺少 %s", errCENCFormat, kind)
}
func cencFind(rows []cencBox, kind string) (cencBox, bool) {
	for _, b := range rows {
		if b.kind == kind {
			return b, true
		}
	}
	return cencBox{}, false
}
func (index *cencIndex) patch(offset int64, value string) {
	index.patches = append(index.patches, cencPatch{offset, []byte(value)})
}

func parseCENCMP4(data []byte, base, total int64) (*cencIndex, error) {
	roots, err := cencBoxes(data, 0, len(data))
	if err != nil || len(roots) != 1 || roots[0].kind != "moov" {
		return nil, errCENCFormat
	}
	rows, err := cencBoxes(data, roots[0].body, roots[0].end)
	if err != nil {
		return nil, err
	}
	index := &cencIndex{total: total}
	for _, box := range rows {
		switch box.kind {
		case "mvex":
			return nil, fmt.Errorf("%w：分片 MP4", errCENCFormat)
		case "pssh":
			index.patch(base+int64(box.start+4), "free")
		case "trak":
			if err = index.track(data, box, base); err != nil {
				return nil, err
			}
		}
	}
	sort.Slice(index.spans, func(i, j int) bool { return index.spans[i].start < index.spans[j].start })
	for i, span := range index.spans {
		if span.start < 0 || span.end > total || span.start >= span.end || i > 0 && index.spans[i-1].end > span.start {
			return nil, errCENCFormat
		}
	}
	if len(index.spans) == 0 {
		return nil, fmt.Errorf("%w：没有加密采样", errCENCFormat)
	}
	return index, nil
}
func (index *cencIndex) track(data []byte, trak cencBox, base int64) error {
	box := trak
	var err error
	for _, kind := range []string{"mdia", "minf", "stbl"} {
		box, err = cencChild(data, box, kind)
		if err != nil {
			return err
		}
	}
	rows, err := cencBoxes(data, box.body, box.end)
	if err != nil {
		return err
	}
	stsd, ok := cencFind(rows, "stsd")
	if !ok || stsd.end-stsd.body < 8 {
		return errCENCFormat
	}
	entries, err := cencBoxes(data, stsd.body+8, stsd.end)
	if err != nil {
		return err
	}
	encrypted := false
	ivSize := 0
	for entryNumber, entry := range entries {
		if entry.kind != "encv" && entry.kind != "enca" {
			continue
		}
		if encrypted || entryNumber != 0 || len(entries) != 1 {
			return errCENCFormat
		}
		skip := 78
		if entry.kind == "enca" {
			skip = 28
			if entry.end-entry.body < 28 || binary.BigEndian.Uint16(data[entry.body+8:]) != 0 {
				return errCENCFormat
			}
		}
		children, err := cencBoxes(data, entry.body+skip, entry.end)
		if err != nil {
			return err
		}
		sinf, ok := cencFind(children, "sinf")
		if !ok {
			return errCENCFormat
		}
		frma, err := cencChild(data, sinf, "frma")
		if err != nil || frma.end-frma.body != 4 {
			return errCENCFormat
		}
		schm, err := cencChild(data, sinf, "schm")
		if err != nil || schm.end-schm.body < 8 || string(data[schm.body+4:schm.body+8]) != "cenc" {
			return errCENCFormat
		}
		schi, err := cencChild(data, sinf, "schi")
		if err != nil {
			return err
		}
		tenc, err := cencChild(data, schi, "tenc")
		if err != nil || tenc.end-tenc.body < 24 {
			return errCENCFormat
		}
		if data[tenc.body] > 1 || data[tenc.body+5] != 0 || data[tenc.body+6] != 1 {
			return errCENCFormat
		}
		ivSize = int(data[tenc.body+7])
		if ivSize != 8 && ivSize != 16 {
			return errCENCFormat
		}
		index.patch(base+int64(entry.start+4), string(data[frma.body:frma.end]))
		index.patch(base+int64(sinf.start+4), "free")
		encrypted = true
	}
	if !encrypted {
		return nil
	}
	for _, row := range rows {
		if (row.kind == "sgpd" || row.kind == "sbgp") && row.end-row.body >= 8 && string(data[row.body+4:row.body+8]) == "seig" {
			return errCENCFormat
		}
	}
	sizes, err := cencSizes(data, rows)
	if err != nil {
		return err
	}
	offsets, err := cencOffsets(data, rows, sizes, index.total)
	if err != nil {
		return err
	}
	senc, ok := cencFind(rows, "senc")
	if !ok || senc.end-senc.body < 8 {
		return fmt.Errorf("%w：缺少采样加密表", errCENCFormat)
	}
	flags := binary.BigEndian.Uint32(data[senc.body:])
	if flags&^uint32(2) != 0 || int(binary.BigEndian.Uint32(data[senc.body+4:])) != len(sizes) {
		return errCENCFormat
	}
	p := senc.body + 8
	for i, size := range sizes {
		if p+ivSize > senc.end {
			return errCENCFormat
		}
		var iv [16]byte
		copy(iv[:], data[p:p+ivSize])
		p += ivSize
		if flags&2 == 0 {
			if size > 0 {
				index.spans = append(index.spans, cencSpan{offsets[i], offsets[i] + int64(size), 0, iv})
			}
			continue
		}
		if p+2 > senc.end {
			return errCENCFormat
		}
		count := int(binary.BigEndian.Uint16(data[p:]))
		p += 2
		if count == 0 || count > (senc.end-p)/6 {
			return errCENCFormat
		}
		position := offsets[i]
		encryptedOffset := int64(0)
		for j := 0; j < count; j++ {
			clear := int64(binary.BigEndian.Uint16(data[p:]))
			length := int64(binary.BigEndian.Uint32(data[p+2:]))
			p += 6
			position += clear
			if position > offsets[i]+int64(size) || length > offsets[i]+int64(size)-position {
				return errCENCFormat
			}
			if length > 0 {
				index.spans = append(index.spans, cencSpan{position, position + length, encryptedOffset, iv})
			}
			position += length
			encryptedOffset += length
			if len(index.spans) > cencSampleLimit*4 {
				return errCENCFormat
			}
		}
		if position != offsets[i]+int64(size) {
			return errCENCFormat
		}
	}
	if p != senc.end {
		return errCENCFormat
	}
	for _, row := range rows {
		if row.kind == "senc" || row.kind == "saiz" || row.kind == "saio" {
			index.patch(base+int64(row.start+4), "free")
		}
	}
	return nil
}
func cencSizes(data []byte, rows []cencBox) ([]uint32, error) {
	b, ok := cencFind(rows, "stsz")
	if !ok || b.end-b.body < 12 {
		return nil, errCENCFormat
	}
	uniform := binary.BigEndian.Uint32(data[b.body+4:])
	count := int(binary.BigEndian.Uint32(data[b.body+8:]))
	if count < 1 || count > cencSampleLimit || uniform == 0 && count > (b.end-b.body-12)/4 {
		return nil, errCENCFormat
	}
	sizes := make([]uint32, count)
	for i := range sizes {
		sizes[i] = uniform
		if uniform == 0 {
			sizes[i] = binary.BigEndian.Uint32(data[b.body+12+i*4:])
		}
	}
	return sizes, nil
}
func cencOffsets(data []byte, rows []cencBox, sizes []uint32, total int64) ([]int64, error) {
	b, ok := cencFind(rows, "stco")
	width := 4
	if !ok {
		b, ok = cencFind(rows, "co64")
		width = 8
	}
	if !ok || b.end-b.body < 8 {
		return nil, errCENCFormat
	}
	count := int(binary.BigEndian.Uint32(data[b.body+4:]))
	if count < 1 || count > cencSampleLimit || count > (b.end-b.body-8)/width {
		return nil, errCENCFormat
	}
	sc, ok := cencFind(rows, "stsc")
	if !ok || sc.end-sc.body < 8 {
		return nil, errCENCFormat
	}
	n := int(binary.BigEndian.Uint32(data[sc.body+4:]))
	if n < 1 || n > count || n > (sc.end-sc.body-8)/12 {
		return nil, errCENCFormat
	}
	type chunkRule struct{ first, samples int }
	rules := make([]chunkRule, n)
	for i := range rules {
		p := sc.body + 8 + i*12
		rules[i] = chunkRule{int(binary.BigEndian.Uint32(data[p:])), int(binary.BigEndian.Uint32(data[p+4:]))}
		if rules[i].samples < 1 || rules[i].first < 1 || rules[i].first > count || i == 0 && rules[i].first != 1 || i > 0 && rules[i].first <= rules[i-1].first || binary.BigEndian.Uint32(data[p+8:]) != 1 {
			return nil, errCENCFormat
		}
	}
	offsets := make([]int64, len(sizes))
	sample, rule := 0, 0
	for chunk := 1; chunk <= count; chunk++ {
		if rule+1 < len(rules) && chunk >= rules[rule+1].first {
			rule++
		}
		p := b.body + 8 + (chunk-1)*width
		var offset uint64
		if width == 8 {
			offset = binary.BigEndian.Uint64(data[p:])
		} else {
			offset = uint64(binary.BigEndian.Uint32(data[p:]))
		}
		for j := 0; j < rules[rule].samples; j++ {
			if sample >= len(sizes) || offset > uint64(total) || uint64(sizes[sample]) > uint64(total)-offset {
				return nil, errCENCFormat
			}
			offsets[sample] = int64(offset)
			offset += uint64(sizes[sample])
			sample++
		}
	}
	if sample != len(sizes) {
		return nil, errCENCFormat
	}
	return offsets, nil
}
func (index *cencIndex) transform(data []byte, offset int64, block cipher.Block) {
	end := offset + int64(len(data))
	for i := sort.Search(len(index.spans), func(i int) bool { return index.spans[i].end > offset }); i < len(index.spans) && index.spans[i].start < end; i++ {
		span := index.spans[i]
		start, stop := max(offset, span.start), min(end, span.end)
		position := span.counterOffset + start - span.start
		counter := span.iv
		carry := uint64(position / 16)
		for j := 15; j >= 0 && carry > 0; j-- {
			sum := uint64(counter[j]) + (carry & 255)
			counter[j] = byte(sum)
			carry = (carry >> 8) + (sum >> 8)
		}
		stream := cipher.NewCTR(block, counter[:])
		var skip [16]byte
		stream.XORKeyStream(skip[:position%16], skip[:position%16])
		part := data[start-offset : stop-offset]
		stream.XORKeyStream(part, part)
	}
	for _, patch := range index.patches {
		a, b := max(offset, patch.offset), min(end, patch.offset+int64(len(patch.data)))
		if a < b {
			copy(data[a-offset:b-offset], patch.data[a-patch.offset:b-patch.offset])
		}
	}
}
