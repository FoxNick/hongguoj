package core

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

func startTestEpisodeCache(t *testing.T, media providerMedia) (*nativeEngine, nativePlan, string) {
	t.Helper()
	engine, err := newNativeEngine(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	plan, err := engine.nativeOpenPlayback(context.Background(), nativePlaybackChoices(media, 0))
	if err != nil {
		t.Fatal(err)
	}
	input := downloadTestInput(1)
	input.Index = 2
	choice := engine.playbacks[plan.Session]
	if err := engine.startEpisodeCache(input, plan, choice, engine.stream); err != nil {
		t.Fatal(err)
	}
	cache := engine.stream.sessions[choice.streamSession].preload
	t.Cleanup(func() {
		engine.nativeReleasePlayback(plan.Session)
		engine.stream.server.Close()
		deadline := time.Now().Add(time.Second)
		for time.Now().Before(deadline) {
			if _, err := os.Stat(cache.manager.root); os.IsNotExist(err) {
				return
			}
			time.Sleep(time.Millisecond)
		}
		t.Error("released cache was not removed")
	})
	return engine, plan, cache.directory
}

func waitTestEpisodeCache(t *testing.T, engine *nativeEngine, plan nativePlan, predicate func(nativePlan) bool) nativePlan {
	t.Helper()
	deadline := time.Now().Add(8 * time.Second)
	for time.Now().Before(deadline) {
		current, err := engine.nativePreloadStatus(plan.Session)
		if err != nil {
			t.Fatal(err)
		}
		if predicate(current) {
			return current
		}
		time.Sleep(5 * time.Millisecond)
	}
	current, _ := engine.nativePreloadStatus(plan.Session)
	t.Fatalf("cache did not reach expected state: %+v", current)
	return nativePlan{}
}

func TestEpisodeCacheWholeFileResumeAndOfflinePlayback(t *testing.T) {
	data := bytes.Repeat([]byte("synthetic-full-episode"), 300000)
	var requests atomic.Int32
	var resumed atomic.Bool
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "video/mp4")
		w.Header().Set("ETag", `"stable"`)
		if requests.Add(1) == 1 {
			w.Header().Set("Content-Length", fmt.Sprint(len(data)))
			w.Write(data[:1<<20])
			return
		}
		if r.Header.Get("Range") == "bytes=1048576-" && r.Header.Get("If-Range") == `"stable"` {
			resumed.Store(true)
		}
		http.ServeContent(w, r, "media.mp4", time.Time{}, bytes.NewReader(data))
	}))
	defer upstream.Close()
	engine, plan, _ := startTestEpisodeCache(t, providerMedia{URL: upstream.URL + "/media.mp4"})
	waitTestEpisodeCache(t, engine, plan, func(p nativePlan) bool { return p.PreloadState == "retrying" && !p.PreloadComplete })
	complete := waitTestEpisodeCache(t, engine, plan, func(p nativePlan) bool { return p.PreloadComplete })
	if !resumed.Load() || complete.PrefetchedBytes != int64(len(data)) || complete.PreloadTotal != int64(len(data)) || complete.PreloadProgress != 1 {
		t.Fatalf("invalid completion or no resume: %+v, resume=%v", complete, resumed.Load())
	}
	upstream.Close()
	response, err := http.Get(plan.URL)
	if err != nil {
		t.Fatal(err)
	}
	body, err := io.ReadAll(response.Body)
	response.Body.Close()
	if err != nil || response.StatusCode != 200 || !bytes.Equal(body, data) {
		t.Fatalf("offline cached bytes differ: %v, status=%d", err, response.StatusCode)
	}
}

func TestEpisodeCacheHLSIncludesEverySegmentAndKey(t *testing.T) {
	testEpisodeCacheHLSResources(t, "/index.m3u8")
}

func TestEpisodeCacheExtensionlessHLSIsNotACompleteVideo(t *testing.T) {
	testEpisodeCacheHLSResources(t, "/opaque")
}

func testEpisodeCacheHLSResources(t *testing.T, entry string) {
	t.Helper()
	key := "0123456789abcdef"
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/index.m3u8", "/opaque":
			io.WriteString(w, "#EXTM3U\n#EXT-X-TARGETDURATION:10\n#EXT-X-KEY:METHOD=AES-128,URI=\"key\"\n#EXTINF:10,\none.ts\n#EXTINF:10,\ntwo.ts\n#EXTINF:10,\nthree.ts\n#EXT-X-ENDLIST\n")
		case "/key":
			io.WriteString(w, key)
		default:
			io.WriteString(w, "synthetic "+r.URL.Path)
		}
	}))
	defer upstream.Close()
	engine, plan, directory := startTestEpisodeCache(t, providerMedia{URL: upstream.URL + entry})
	waitTestEpisodeCache(t, engine, plan, func(p nativePlan) bool { return p.PreloadComplete })
	upstream.Close()
	response, err := http.Get(plan.URL)
	if err != nil {
		t.Fatal(err)
	}
	body, _ := io.ReadAll(response.Body)
	response.Body.Close()
	if response.StatusCode != 200 || !bytes.Contains(body, []byte("#EXT-X-ENDLIST")) {
		t.Fatalf("offline playlist invalid: %s", body)
	}
	var urls []string
	for _, match := range nativePlaylistURI.FindAllStringSubmatch(string(body), -1) {
		urls = append(urls, match[1])
	}
	for _, line := range strings.Split(string(body), "\n") {
		if strings.HasPrefix(line, "http:") {
			urls = append(urls, line)
		}
	}
	if len(urls) != 4 {
		t.Fatalf("not all HLS resources cached: %v", urls)
	}
	for _, address := range urls {
		response, err := http.Get(address)
		if err != nil {
			t.Fatal(err)
		}
		data, _ := io.ReadAll(response.Body)
		response.Body.Close()
		if response.StatusCode != 200 || len(data) == 0 {
			t.Fatalf("offline asset unavailable: %s", address)
		}
	}
	playlists, _ := filepath.Glob(filepath.Join(directory, "*.m3u8"))
	if len(playlists) != 1 {
		t.Fatalf("unexpected cached playlists: %v", playlists)
	}
	if err := os.WriteFile(playlists[0], []byte("truncated"), 0600); err != nil {
		t.Fatal(err)
	}
	broken, _ := http.Get(plan.URL)
	broken.Body.Close()
	if broken.StatusCode != http.StatusGone {
		t.Fatalf("changed file silently accepted: %d", broken.StatusCode)
	}
}

func TestEpisodeCacheNeverCompletesEmptyOrShortResponse(t *testing.T) {
	for _, payload := range []string{"", "short"} {
		t.Run(fmt.Sprint(len(payload)), func(t *testing.T) {
			upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.Header().Set("Content-Length", "1024")
				io.WriteString(w, payload)
			}))
			defer upstream.Close()
			engine, plan, _ := startTestEpisodeCache(t, providerMedia{URL: upstream.URL + "/media.mp4"})
			state := waitTestEpisodeCache(t, engine, plan, func(p nativePlan) bool { return p.PreloadState == "retrying" })
			if state.PreloadComplete || state.PreloadProgress >= 1 || state.PreloadError == "" {
				t.Fatalf("incomplete response reported ready: %+v", state)
			}
		})
	}
}

func TestEpisodeCacheIncompleteHandoffKeepsCurrentMediaStable(t *testing.T) {
	release := make(chan struct{})
	var gets atomic.Int32
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet && gets.Add(1) == 1 {
			select {
			case <-release:
			case <-r.Context().Done():
				return
			}
		}
		w.Header().Set("Content-Type", "video/mp4")
		http.ServeContent(w, r, "media.mp4", time.Time{}, bytes.NewReader([]byte("synthetic stable media")))
	}))
	defer upstream.Close()
	engine, plan, _ := startTestEpisodeCache(t, providerMedia{URL: upstream.URL + "/media.mp4"})
	response, err := http.Head(plan.URL)
	if err != nil {
		t.Fatal(err)
	}
	response.Body.Close()
	close(release)
	waitTestEpisodeCache(t, engine, plan, func(p nativePlan) bool { return p.PreloadComplete })
	response, err = http.Get(plan.URL)
	if err != nil {
		t.Fatal(err)
	}
	io.Copy(io.Discard, response.Body)
	response.Body.Close()
	if gets.Load() != 2 {
		t.Fatalf("media switched underneath active online playback: requests=%d", gets.Load())
	}
}
