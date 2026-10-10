import 'package:flutter/material.dart';

import 'player_interactions.dart';

class EpisodeSwipeSurface extends StatefulWidget {
  const EpisodeSwipeSurface({
    super.key,
    required this.interactions,
    required this.enabled,
    required this.previousLabel,
    required this.nextLabel,
    required this.child,
  });
  final PlayerInteractions interactions;
  final bool enabled;
  final String previousLabel;
  final String nextLabel;
  final Widget child;

  @override
  State<EpisodeSwipeSurface> createState() => _EpisodeSwipeSurfaceState();
}

class _EpisodeSwipeSurfaceState extends State<EpisodeSwipeSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController.unbounded(
    vsync: this,
  );
  double _height = 1;
  bool _committed = false;
  String _preview = '';
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    widget.interactions.addListener(_sync);
  }

  @override
  void didUpdateWidget(EpisodeSwipeSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interactions != oldWidget.interactions) {
      oldWidget.interactions.removeListener(_sync);
      widget.interactions.addListener(_sync);
    }
    if (!widget.enabled) {
      _motion.stop();
      _motion.value = 0;
      _committed = false;
    }
  }

  void _sync() {
    if (!mounted || !widget.enabled) return;
    final gestures = widget.interactions;
    if (gestures.episodeCommit != 0) {
      if (_committed) return;
      _committed = true;
      _direction = gestures.episodeCommit;
      _motion.animateTo(
        -_direction.toDouble(),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else if (gestures.episodeDragging) {
      _direction = gestures.episodeDrag < 0 ? 1 : -1;
      _preview = _direction > 0 ? widget.nextLabel : widget.previousLabel;
      _motion.stop();
      _motion.value = (gestures.episodeDrag / _height).clamp(-1.0, 1.0);
    } else if (_committed) {
      _committed = false;
      _motion.stop();
      _motion.value = 0;
    } else if (_motion.value != 0 && !_motion.isAnimating) {
      _motion.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    widget.interactions.removeListener(_sync);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _height = constraints.maxHeight > 0 ? constraints.maxHeight : 1;
      return AnimatedBuilder(
        animation: _motion,
        child: widget.child,
        builder: (context, child) => ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.enabled && _motion.value != 0)
                Transform.translate(
                  offset: Offset(0, (_motion.value + _direction) * _height),
                  child: ColoredBox(
                    color: const Color(0xFF111116),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _direction > 0
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white54,
                              size: 28,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _preview,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _committed ? '正在接续播放' : '松开切换',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Transform.translate(
                key: const ValueKey('episode-swipe-page'),
                offset: Offset(0, widget.enabled ? _motion.value * _height : 0),
                child: child,
              ),
            ],
          ),
        ),
      );
    },
  );
}
