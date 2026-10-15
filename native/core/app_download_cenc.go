package core

import (
	"crypto/aes"
	"errors"
	"os"
	"path"
	"strings"
)

const nativeDownloadCENCLimit = 512 << 20

func nativeDownloadCENCMedia(name string) bool {
	switch strings.ToLower(path.Ext(name)) {
	case ".mp4", ".m4s", ".mov", ".m4v":
		return true
	}
	return false
}

// nativeDecryptDownloadedCENC 把已落盘的 CENC 加密 MP4 就地还原为明文，
// 使下载产物能被系统播放器、剪辑软件和合并管线直接使用。
// 结构不支持时保持原文件不动并返回 false，由调用方按普通下载处理。
func nativeDecryptDownloadedCENC(target string, key []byte) (bool, error) {
	if len(key) != aes.BlockSize {
		return false, nil
	}
	info, err := os.Stat(target)
	if err != nil {
		return false, err
	}
	if info.Size() < 8 || info.Size() > nativeDownloadCENCLimit {
		return false, nil
	}
	data, err := os.ReadFile(target)
	if err != nil {
		return false, err
	}
	total := int64(len(data))
	index, err := parseCENCMP4(data, 0, total)
	if err != nil {
		if errors.Is(err, errCENCFormat) {
			return false, nil
		}
		return false, err
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return false, err
	}
	index.transform(data, 0, block)
	if err = nativeDownloadWrite(target, data); err != nil {
		return false, err
	}
	return true, nil
}
