package io.flutter.plugins.videoplayer;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

import androidx.media3.common.C;
import androidx.media3.common.Player;
import androidx.media3.common.Tracks;
import androidx.media3.common.VideoSize;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.source.MediaSource;
import io.flutter.plugin.common.MethodChannel;
import java.util.concurrent.TimeUnit;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import org.robolectric.shadows.ShadowLooper;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = 34)
public class PlaybackTransitionTest {
  private ExoPlayer player;
  private PlaybackTransition transition;
  private MethodChannel.Result result;
  private MediaSource source;

  @Before
  public void setUp() {
    player = mock(ExoPlayer.class);
    Tracks tracks = mock(Tracks.class);
    when(tracks.isTypeSupported(C.TRACK_TYPE_VIDEO)).thenReturn(true);
    when(player.getCurrentTracks()).thenReturn(tracks);
    when(player.getDuration()).thenReturn(90000L);
    when(player.getVideoSize()).thenReturn(new VideoSize(1920, 1080));
    source = mock(MediaSource.class);
    result = mock(MethodChannel.Result.class);
    transition = new PlaybackTransition(player);
  }

  @Test
  public void readyWaitsForFirstFrameWithoutReleasingPlayerOrSurface() {
    transition.replace(source, result);
    verify(player).setPlayWhenReady(false);
    verify(player).setMediaSource(source);
    verify(player).prepare();
    transition.onPlaybackStateChanged(Player.STATE_READY);
    verifyNoInteractions(result);
    assertTrue(transition.pending());
    transition.onRenderedFirstFrame();
    verify(result).success(argThat(value ->
        ((java.util.Map<?, ?>) value).get("durationMs").equals(90000L)));
    assertFalse(transition.pending());
    verify(player, never()).release();
    verify(player, never()).clearVideoSurface();
    transition.onRenderedFirstFrame();
    verify(result, times(1)).success(any());
  }

  @Test
  public void timeoutAndDisposeReplyOnceAndDetachListener() {
    transition.replace(source, result);
    ShadowLooper.idleMainLooper(8, TimeUnit.SECONDS);
    verify(result).error(eq("transition_timeout"), anyString(), isNull());
    verify(player).removeListener(transition);
    assertFalse(transition.pending());
    transition.dispose();
    transition.onRenderedFirstFrame();
    verify(result, never()).success(any());
    verifyNoMoreInteractions(result);
  }

  @Test
  public void readyWithoutFirstFrameReturnsPreparationResultAfterGrace() {
    transition.replace(source, result);
    transition.onPlaybackStateChanged(Player.STATE_READY);
    ShadowLooper.idleMainLooper(250, TimeUnit.MILLISECONDS);
    verify(result).success(argThat(value ->
        Boolean.FALSE.equals(((java.util.Map<?, ?>) value).get("firstFrame"))));
    assertFalse(transition.pending());
    verify(player, never()).release();
    ShadowLooper.idleMainLooper(8, TimeUnit.SECONDS);
    transition.onRenderedFirstFrame();
    verify(result, times(1)).success(any());
    verify(result, never()).error(anyString(), anyString(), any());
  }

  @Test
  public void bufferingCancelsReadyGraceUntilReadyAgain() {
    transition.replace(source, result);
    transition.onPlaybackStateChanged(Player.STATE_READY);
    transition.onPlaybackStateChanged(Player.STATE_BUFFERING);
    ShadowLooper.idleMainLooper(300, TimeUnit.MILLISECONDS);
    verifyNoInteractions(result);
    transition.onPlaybackStateChanged(Player.STATE_READY);
    ShadowLooper.idleMainLooper(250, TimeUnit.MILLISECONDS);
    verify(result).success(any());
  }

  @Test
  public void unknownDurationDoesNotPreventPreparedMediaFromStarting() {
    when(player.getDuration()).thenReturn(C.TIME_UNSET);
    transition.replace(source, result);
    transition.onPlaybackStateChanged(Player.STATE_READY);
    transition.onRenderedFirstFrame();
    ShadowLooper.idleMainLooper(250, TimeUnit.MILLISECONDS);
    verify(result).success(argThat(value ->
        ((java.util.Map<?, ?>) value).get("durationMs").equals(0L)));
  }

  @Test
  public void replacementCancelsOnlyPreviousPendingReply() {
    transition.replace(source, result);
    MethodChannel.Result next = mock(MethodChannel.Result.class);
    transition.replace(source, next);
    verify(result).error(eq("transition_cancelled"), anyString(), isNull());
    transition.onRenderedFirstFrame();
    verifyNoInteractions(next);
    transition.onPlaybackStateChanged(Player.STATE_READY);
    verify(next).success(any());
    verify(result, never()).success(any());
  }
}
