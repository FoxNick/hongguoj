package core

import (
	"bytes"
	"context"
	"crypto/aes"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"sync/atomic"
	"testing"
	"time"
)

func TestCENCStreamDecodeAndRanges(t *testing.T) {
	ffmpeg, err := exec.LookPath("ffmpeg")
	if err != nil {
		t.Skip("FFmpeg is required for the independent media decoder")
	}
	directory := t.TempDir()
	input := filepath.Join(directory, "encrypted.mp4")
	keyHex := "00112233445566778899aabbccddeeff"
	key, _ := hex.DecodeString(keyHex)
	run := func(args ...string) []byte {
		t.Helper()
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		out, err := exec.CommandContext(ctx, ffmpeg, append([]string{"-hide_banner", "-loglevel", "error", "-nostdin", "-xerror"}, args...)...).CombinedOutput()
		if err != nil {
			t.Fatalf("FFmpeg failed: %v: %s", err, out)
		}
		return out
	}
	run("-f", "lavfi", "-i", "testsrc2=size=160x96:rate=10", "-f", "lavfi", "-i", "sine=frequency=440:sample_rate=48000", "-t", "2", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-c:a", "aac", "-movflags", "+faststart", "-encryption_scheme", "cenc-aes-ctr", "-encryption_key", keyHex, "-encryption_kid", "0123456789abcdef0123456789abcdef", input)
	encrypted, err := os.ReadFile(input)
	if err != nil {
		t.Fatal(err)
	}
	var upstreamCalls atomic.Int32
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		upstreamCalls.Add(1)
		w.Header().Set("ETag", `"synthetic-v1"`)
		w.Header().Set("Content-Type", "video/mp4")
		http.ServeContent(w, r, "video.mp4", time.Time{}, bytes.NewReader(encrypted))
	}))
	defer upstream.Close()
	engine, err := newNativeEngine(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	stream, err := newNativeStreamServer(engine.downloader)
	if err != nil {
		t.Fatal(err)
	}
	defer stream.server.Close()
	var clear []byte
	for _, option := range []struct {
		address  string
		prefetch bool
		whole    bool
	}{{upstream.URL + "/video.mp4", false, false}, {input, false, false}, {upstream.URL + "/video.mp4", true, false}, {upstream.URL + "/video.mp4", false, true}} {
		media := providerMedia{URL: option.address, CENCKey: key}
		var playback, token string
		if option.whole {
			engine.stream = stream
			plan, err := engine.nativeOpenPlayback(context.Background(), nativePlaybackChoices(media, 0))
			if err != nil {
				t.Fatal(err)
			}
			choice := engine.playbacks[plan.Session]
			if err := engine.startEpisodeCache(downloadTestInput(1), plan, choice, stream); err != nil {
				t.Fatal(err)
			}
			waitTestEpisodeCache(t, engine, plan, func(p nativePlan) bool { return p.PreloadComplete })
			playback, token = plan.URL, choice.streamSession
			defer engine.nativeReleasePlayback(plan.Session)
		} else {
			playback, token = stream.nativeOpen(media)
		}
		defer stream.nativeRelease(token)
		playback += "?cenc=clear"
		if option.prefetch {
			if fetched := stream.nativePrefetch(context.Background(), token, playback, 0); fetched != int64(len(encrypted)) {
				t.Fatalf("prefetched bytes=%d want=%d", fetched, len(encrypted))
			}
			if stream.sessions[token].cenc == nil {
				t.Fatal("preload did not prepare CENC metadata")
			}
		}
		callsBefore := upstreamCalls.Load()
		response, err := http.Get(playback)
		if err != nil {
			t.Fatal(err)
		}
		data, err := io.ReadAll(response.Body)
		response.Body.Close()
		if err != nil || response.StatusCode != 200 || response.Header.Get("X-Hongguo-Media") != "clear-cenc-mp4" || len(data) != len(encrypted) {
			t.Fatalf("clear stream status=%d bytes=%d error=%v body prefix=%.180s", response.StatusCode, len(data), err, data)
		}
		if clear == nil {
			clear = data
		} else if !bytes.Equal(clear, data) {
			t.Fatal("local and network decrypt differ")
		}
		for _, region := range [][2]int{{0, 8}, {5, 8}, {42, 19}, {len(data)/2 + 3, 97}, {len(data) - 17, 17}} {
			request, _ := http.NewRequest(http.MethodGet, playback, nil)
			request.Header.Set("Range", fmt.Sprintf("bytes=%d-%d", region[0], region[0]+region[1]-1))
			response, err := http.DefaultClient.Do(request)
			if err != nil {
				t.Fatal(err)
			}
			part, err := io.ReadAll(response.Body)
			response.Body.Close()
			if err != nil || response.StatusCode != 206 || !bytes.Equal(part, data[region[0]:region[0]+region[1]]) {
				t.Fatalf("range %v differs: status=%d error=%v", region, response.StatusCode, err)
			}
		}
		head, err := http.Head(playback)
		if err != nil {
			t.Fatal(err)
		}
		head.Body.Close()
		if head.StatusCode != 200 || head.ContentLength != int64(len(data)) {
			t.Fatal("HEAD changed length")
		}
		request, _ := http.NewRequest(http.MethodGet, playback, nil)
		request.Header.Set("Range", fmt.Sprintf("bytes=%d-", len(data)))
		invalid, err := http.DefaultClient.Do(request)
		if err != nil {
			t.Fatal(err)
		}
		invalid.Body.Close()
		if invalid.StatusCode != 416 {
			t.Fatalf("unsatisfiable range returned %d", invalid.StatusCode)
		}
		if (option.prefetch || option.whole) && upstreamCalls.Load() != callsBefore {
			t.Fatal("preloaded playback fetched the same media again")
		}
	}
	output := filepath.Join(directory, "clear.mp4")
	if err = os.WriteFile(output, clear, 0600); err != nil {
		t.Fatal(err)
	}
	want := run("-decryption_key", keyHex, "-i", input, "-map", "0:v:0", "-map", "0:a:0", "-f", "framemd5", "-")
	got := run("-i", output, "-map", "0:v:0", "-map", "0:a:0", "-f", "framemd5", "-")
	if !bytes.Equal(want, got) {
		t.Fatal("audio/video frames differ from FFmpeg decryption oracle")
	}
	t.Log("Network and local clear MP4 decode without a player key; all audio/video frame hashes match FFmpeg CENC decryption; arbitrary Range, HEAD and 416 checks passed")
	block, _ := aes.NewCipher(key)
	source := &cencSource{asset: nativeStreamAsset{address: input}, ctx: context.Background()}
	index, err := source.index()
	if err != nil {
		t.Fatal(err)
	}
	for offset := 0; offset < len(encrypted); offset += 37 {
		end := min(offset+37, len(encrypted))
		part := append([]byte(nil), encrypted[offset:end]...)
		index.transform(part, int64(offset), block)
		if !bytes.Equal(part, clear[offset:end]) {
			t.Fatalf("unaligned read at %d differs", offset)
		}
	}
	for _, bad := range [][]byte{nil, {0, 0, 0, 1, 'm', 'o', 'o', 'v'}, {0, 0, 0, 9, 'm', 'o', 'o', 'v', 0}} {
		if _, err := parseCENCMP4(bad, 0, 100); err == nil {
			t.Fatal("malformed metadata accepted")
		}
	}
}

func TestCENCPrefetchedPrefixIsImmediateAndValidatesRemainingBytes(t *testing.T) {
	data := bytes.Repeat([]byte("0123456789abcdef"), 32)
	var calls atomic.Int32
	var changed atomic.Bool
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls.Add(1)
		if r.Header.Get("Range") != "bytes=32-127" || r.Header.Get("If-Match") != `"v1"` {
			t.Error("remainder did not use the cached validator and exact byte range")
		}
		etag := `"v1"`
		if changed.Load() {
			etag = `"v2"`
		}
		w.Header().Set("ETag", etag)
		http.ServeContent(w, r, "video.mp4", time.Time{}, bytes.NewReader(data))
	}))
	defer upstream.Close()
	engine, err := newNativeEngine(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	stream := &nativeStreamServer{downloader: engine.downloader}
	source := func() *cencSource {
		return &cencSource{stream: stream, session: &nativeStreamSession{}, ctx: context.Background(), asset: nativeStreamAsset{address: upstream.URL, data: data[:32], total: int64(len(data)), etag: `"v1"`}}
	}
	reader, err := source().open(0, 128)
	if err != nil {
		t.Fatal(err)
	}
	prefix := make([]byte, 32)
	if _, err := io.ReadFull(reader, prefix); err != nil || !bytes.Equal(prefix, data[:32]) || calls.Load() != 0 {
		t.Fatal("cached prefix waited for the upstream")
	}
	rest, err := io.ReadAll(reader)
	reader.Close()
	if err != nil || !bytes.Equal(rest, data[32:128]) || calls.Load() != 1 {
		t.Fatalf("cached and remote bytes differ: %v", err)
	}
	reader, err = source().open(0, 128)
	if err != nil {
		t.Fatal(err)
	}
	reader.Close()
	if calls.Load() != 1 {
		t.Fatal("closing an unused preloaded body started a request")
	}
	changed.Store(true)
	reader, err = source().open(0, 128)
	if err != nil {
		t.Fatal(err)
	}
	actual, err := io.ReadAll(reader)
	reader.Close()
	if err == nil || !bytes.Equal(actual, data[:32]) {
		t.Fatal("changed remote bytes were mixed with the cached prefix")
	}
}
