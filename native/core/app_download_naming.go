package core

import (
	"path/filepath"
	"strconv"
	"strings"
)

const nativeDownloadNameLimit = 60

var nativeDownloadReservedNames = map[string]bool{
	"CON": true, "PRN": true, "AUX": true, "NUL": true,
	"COM1": true, "COM2": true, "COM3": true, "COM4": true, "COM5": true,
	"COM6": true, "COM7": true, "COM8": true, "COM9": true,
	"LPT1": true, "LPT2": true, "LPT3": true, "LPT4": true, "LPT5": true,
	"LPT6": true, "LPT7": true, "LPT8": true, "LPT9": true,
}

func nativeDownloadSanitize(value, fallback string) string {
	var builder strings.Builder
	for _, symbol := range value {
		switch {
		case symbol < 0x20 || symbol == 0x7f:
		case strings.ContainsRune(`/\:*?"<>|`, symbol):
			builder.WriteRune('_')
		default:
			builder.WriteRune(symbol)
		}
	}
	name := strings.Trim(strings.Join(strings.Fields(builder.String()), " "), " .")
	if name == "" {
		return fallback
	}
	if runes := []rune(name); len(runes) > nativeDownloadNameLimit {
		name = strings.Trim(string(runes[:nativeDownloadNameLimit]), " .")
	}
	if name == "" {
		return fallback
	}
	if nativeDownloadReservedNames[strings.ToUpper(name)] {
		return name + "_"
	}
	return name
}

type nativeDownloadMarker struct {
	Fingerprint string   `json:"fingerprint"`
	Files       []string `json:"files"`
}

func nativeDownloadPlaylistFile(name string) bool {
	return strings.HasSuffix(strings.ToLower(name), ".m3u8")
}

func nativeDownloadMarkerName(job nativeDownloadJob) string {
	return ".bundle-" + nativeDownloadEpisodeLabel(job.Index)
}

func nativeDownloadFolder(drama nativeDrama) string {
	return nativeDownloadSanitize(drama.Source, "其他") + "/" +
		nativeDownloadSanitize(drama.Title, "未命名短剧")
}

func nativeDownloadEpisodeLabel(index int) string {
	label := strconv.Itoa(index)
	for len(label) < 3 {
		label = "0" + label
	}
	return label
}

func nativeDownloadFileName(drama nativeDrama, index int, extension string) string {
	return nativeDownloadSanitize(drama.Title, "未命名短剧") + " " +
		nativeDownloadEpisodeLabel(index) + extension
}

func nativeDownloadFolderValid(folder string) bool {
	if folder == "" {
		return true
	}
	parts := strings.Split(folder, "/")
	if len(parts) == 0 || len(parts) > 3 {
		return false
	}
	for _, part := range parts {
		if part == "" || part == "." || part == ".." || len(part) > 200 {
			return false
		}
		if part != filepath.Base(part) || strings.ContainsAny(part, `\`) {
			return false
		}
		for _, symbol := range part {
			if symbol < 0x20 || symbol == 0x7f {
				return false
			}
		}
	}
	return true
}

func nativeDownloadFileNameValid(name string) bool {
	if name == "" || name == "." || name == ".." || len(name) > 200 {
		return false
	}
	if name != filepath.Base(name) || strings.ContainsAny(name, `/\`) {
		return false
	}
	for _, symbol := range name {
		if symbol < 0x20 || symbol == 0x7f {
			return false
		}
	}
	return true
}
