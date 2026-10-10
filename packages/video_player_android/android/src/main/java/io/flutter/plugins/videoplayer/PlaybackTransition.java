package io.flutter.plugins.videoplayer;

import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import androidx.media3.common.C;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.common.VideoSize;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.source.MediaSource;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import java.util.Map;

@UnstableApi
final class PlaybackTransition implements Player.Listener {
  private final ExoPlayer player;
  private final Handler handler = new Handler(Looper.getMainLooper());
  private MethodChannel.Result result;
  private long startedAt;
  private boolean firstFrame;
  private boolean ready;
  private boolean readyGraceElapsed;
  private final Runnable readyFallback = () -> {
    readyGraceElapsed = true;
    finishIfReady();
  };
  private final Runnable timeout = () -> fail("transition_timeout", "下一集首帧等待超时");

  PlaybackTransition(ExoPlayer player) {
    this.player = player;
  }

  boolean pending() {
    return result != null;
  }

  void replace(MediaSource source, MethodChannel.Result reply) {
    fail("transition_cancelled", "切集已被替换");
    result = reply;
    firstFrame = false;
    ready = false;
    readyGraceElapsed = false;
    startedAt = SystemClock.elapsedRealtime();
    player.addListener(this);
    handler.postDelayed(timeout, 8000);
    try {
      player.setPlayWhenReady(false);
      player.setMediaSource(source);
      player.prepare();
    } catch (RuntimeException error) {
      fail("transition_failed", error.toString());
    }
  }

  @Override
  public void onPlaybackStateChanged(int state) {
    ready = state == Player.STATE_READY;
    handler.removeCallbacks(readyFallback);
    readyGraceElapsed = false;
    if (ready) handler.postDelayed(readyFallback, 250);
    finishIfReady();
  }

  @Override
  public void onRenderedFirstFrame() {
    firstFrame = true;
    finishIfReady();
  }

  @Override
  public void onPlayerError(PlaybackException error) {
    fail("transition_failed", error.getErrorCodeName() + ": " + error.getMessage());
  }

  private void finishIfReady() {
    if (result == null || !ready) return;
    if (player.getCurrentTracks().isTypeSupported(C.TRACK_TYPE_VIDEO)
        && !firstFrame && !readyGraceElapsed) return;
    final long duration = player.getDuration();
    if (duration == C.TIME_UNSET && !readyGraceElapsed) return;
    VideoSize size = player.getVideoSize();
    Map<String, Object> values = new HashMap<>();
    values.put("durationMs", duration == C.TIME_UNSET ? 0L : duration);
    values.put("firstFrame", firstFrame);
    values.put("width", size.width * size.pixelWidthHeightRatio);
    values.put("height", size.height);
    values.put("rotation", 0);
    values.put("elapsedMs", SystemClock.elapsedRealtime() - startedAt);
    MethodChannel.Result reply = result;
    clear();
    reply.success(values);
  }

  void dispose() {
    fail("transition_cancelled", "播放器已释放");
  }

  private void fail(String code, String message) {
    if (result == null) return;
    MethodChannel.Result reply = result;
    clear();
    reply.error(code, message, null);
  }

  private void clear() {
    result = null;
    handler.removeCallbacks(timeout);
    handler.removeCallbacks(readyFallback);
    player.removeListener(this);
  }
}
