package io.flutter.plugins.videoplayer;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

import android.view.Surface;
import androidx.media3.common.Format;
import androidx.media3.common.Player;
import androidx.media3.common.Timeline;
import androidx.media3.common.MediaItem;
import androidx.media3.common.VideoSize;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.analytics.AnalyticsListener;
import androidx.media3.test.utils.FakeTimeline;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.videoplayer.platformview.PlatformViewVideoPlayer;
import io.flutter.plugins.videoplayer.texture.TextureVideoPlayer;
import io.flutter.view.TextureRegistry.SurfaceProducer;
import org.mockito.ArgumentCaptor;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = 34)
public class VideoPlayerCaptureTest {
  @Test
  public void rotatedAnamorphicAndUnknownFramesAreRejectedWithoutDistortingPixels() {
    Format normal = new Format.Builder().setRotationDegrees(0).build();
    assertTrue(VideoPlayer.canCaptureFrame(new VideoSize(1080, 1920), normal));
    assertFalse(VideoPlayer.canCaptureFrame(new VideoSize(1080, 1920),
        normal.buildUpon().setRotationDegrees(90).build()));
    assertFalse(VideoPlayer.canCaptureFrame(new VideoSize(1080, 1920, 1.5f), normal));
    assertFalse(VideoPlayer.canCaptureFrame(new VideoSize(0, 0), normal));
    assertFalse(VideoPlayer.canCaptureFrame(new VideoSize(1080, 1920), null));
  }

  @Test
  public void platformViewAndDisposedPlayersReturnNullWithoutCapturing() {
    ExoPlayer exoPlayer = mock(ExoPlayer.class);
    VideoPlayer player = new PlatformViewVideoPlayer(mock(VideoPlayerCallbacks.class),
        MediaItem.fromUri("http://127.0.0.1/unused"), new VideoPlayerOptions(), () -> exoPlayer);
    MethodChannel.Result result = mock(MethodChannel.Result.class);
    player.captureFrame(result);
    player.dispose();
    player.captureFrame(result);
    verify(result, times(2)).success(null);
    verify(exoPlayer, never()).getVideoSize();
  }
  private static AnalyticsListener.EventTime time(MediaItem item) {
    Timeline timeline = new FakeTimeline(new FakeTimeline.TimelineWindowDefinition.Builder()
        .setMediaItem(item).build());
    return new AnalyticsListener.EventTime(0, timeline, 0, null, 0, timeline, 0, null, 0, 0);
  }

  @Test
  public void readyForNewItemCannotCaptureOldFrameUntilNewItemActuallyRenders() {
    ExoPlayer exoPlayer = mock(ExoPlayer.class);
    SurfaceProducer producer = mock(SurfaceProducer.class);
    when(producer.getSurface()).thenReturn(mock(Surface.class));
    MediaItem first = MediaItem.fromUri("http://127.0.0.1/unused/first");
    MediaItem second = MediaItem.fromUri("http://127.0.0.1/unused/second");
    VideoPlayer player = new TextureVideoPlayer(mock(VideoPlayerCallbacks.class), producer,
        first, new VideoPlayerOptions(), () -> exoPlayer);
    ArgumentCaptor<AnalyticsListener> listener = ArgumentCaptor.forClass(AnalyticsListener.class);
    verify(exoPlayer).addAnalyticsListener(listener.capture());
    listener.getValue().onRenderedFirstFrame(time(first), new Object(), 0);
    when(exoPlayer.getCurrentMediaItem()).thenReturn(second);
    when(exoPlayer.getPlaybackState()).thenReturn(Player.STATE_READY);
    when(exoPlayer.getVideoSize()).thenReturn(new VideoSize(1080, 1920));
    when(exoPlayer.getVideoFormat()).thenReturn(new Format.Builder().setRotationDegrees(0).build());
    clearInvocations(exoPlayer, producer);
    MethodChannel.Result reply = mock(MethodChannel.Result.class);
    player.captureFrame(reply);
    verify(reply).success(null);
    verify(producer, never()).getSurface();
    verify(exoPlayer, never()).getVideoSize();
    listener.getValue().onRenderedFirstFrame(time(second), new Object(), 0);
    player.captureFrame(reply);
    verify(exoPlayer).getVideoSize();
    verify(producer).getSurface();
    player.dispose();
  }

}
