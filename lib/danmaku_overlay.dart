import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'danmaku_controller.dart';
import 'danmaku_models.dart';
import 'danmaku_text.dart';

String danmakuFlightText(DanmakuItem item) {
  final characters = danmakuDisplayText(item.text).characters;
  final text =
      characters.take(100).toString() + (characters.length > 100 ? '…' : '');
  return item.repeatCount > 1 ? '$text  ♥ ${item.repeatCount}' : text;
}

class DanmakuFlight {
  const DanmakuFlight(
    this.item,
    this.text,
    this.lane,
    this.width, {
    this.lifetimeMs = danmakuLifetimeMs,
  });
  final DanmakuItem item;
  final String text;
  final int lane;
  final double width;
  final int lifetimeMs;
}

List<DanmakuFlight> planDanmaku(
  List<DanmakuItem> items, {
  required double width,
  required int rows,
  required double Function(String) measure,
  int lifetimeMs = danmakuLifetimeMs,
}) {
  if (!width.isFinite || width <= 0 || rows < 1 || lifetimeMs <= 0) {
    return const [];
  }
  final lanes = List<DanmakuFlight?>.filled(rows.clamp(1, 4), null);
  final sorted = items.toList()..sort((a, b) => a.timeMs.compareTo(b.timeMs));
  final seen = <String>{};
  final flights = <DanmakuFlight>[];
  for (final item in sorted) {
    if (item.id.isEmpty ||
        item.text.trim().isEmpty ||
        item.timeMs < 0 ||
        !seen.add(item.id)) {
      continue;
    }
    if (flights.reversed
            .takeWhile(
              (flight) => item.timeMs - flight.item.timeMs < lifetimeMs,
            )
            .length >=
        24) {
      continue;
    }
    final text = danmakuFlightText(item);
    final size = measure(text).ceilToDouble() + 8;
    final lane = lanes.indexWhere((previous) {
      if (previous == null) return true;
      final gap = item.timeMs - previous.item.timeMs;
      if (gap >= lifetimeMs) return true;
      return (width + previous.width) * gap / lifetimeMs - previous.width >=
              24 &&
          width - (width + size) * (lifetimeMs - gap) / lifetimeMs >= 24;
    });
    if (lane < 0) continue;
    final flight = DanmakuFlight(item, text, lane, size);
    lanes[lane] = flight;
    flights.add(flight);
  }
  return flights;
}

class DanmakuOverlay extends StatefulWidget {
  const DanmakuOverlay({
    super.key,
    required this.controller,
    required this.aspectRatio,
    this.television = false,
  });
  final DanmakuController controller;
  final double aspectRatio;
  final bool television;

  @override
  State<DanmakuOverlay> createState() => _DanmakuOverlayState();
}

class _DanmakuOverlayState extends State<DanmakuOverlay>
    with SingleTickerProviderStateMixin {
  Object? _layout;
  List<DanmakuFlight> _schedule = const [];
  int _televisionPositionMs = 0;
  int _televisionBaseMs = 0;
  late final Ticker _televisionTicker;
  final _televisionSeen = <String>{};
  List<DanmakuFlight> _televisionFlights = [];
  Object? _televisionLayout;

  @override
  void initState() {
    super.initState();
    _televisionTicker = createTicker((elapsed) {
      _televisionPositionMs = _televisionBaseMs + elapsed.inMilliseconds;
    });
  }

  void _updateTelevision(
    DanmakuController controller,
    double width,
    int rows,
    Object layout,
    double Function(String) measure,
  ) {
    if (_televisionLayout != layout) {
      _televisionLayout = layout;
      _televisionTicker.stop();
      _televisionPositionMs = _televisionBaseMs = 0;
      _televisionSeen.clear();
      _televisionFlights.clear();
    }
    if (controller.moving) {
      if (!_televisionTicker.isActive) {
        _televisionBaseMs = _televisionPositionMs;
        _televisionTicker.start();
      }
    } else {
      _televisionTicker.stop();
    }
    final now = _televisionPositionMs;
    final pixelsPerSecond = width / 32;
    _televisionFlights.removeWhere(
      (flight) => now - flight.item.timeMs >= flight.lifetimeMs,
    );
    final currentItems = {for (final item in controller.items) item.id: item};
    for (var index = 0; index < _televisionFlights.length; index++) {
      final flight = _televisionFlights[index];
      final current = currentItems[flight.item.id];
      if (current == null || current.repeatCount == flight.item.repeatCount) {
        continue;
      }
      final text = danmakuFlightText(current);
      final size = measure(text).ceilToDouble() + 8;
      _televisionFlights[index] = DanmakuFlight(
        DanmakuItem(
          id: current.id,
          text: current.text,
          timeMs: flight.item.timeMs,
          repeatCount: current.repeatCount,
        ),
        text,
        flight.lane,
        size,
        lifetimeMs: ((width + size) / pixelsPerSecond * 1000).ceil(),
      );
    }
    for (final item in controller.items) {
      if (item.timeMs > controller.positionMs ||
          item.timeMs < controller.positionMs - 1000 ||
          !_televisionSeen.add(item.id))
        continue;
      final text = danmakuFlightText(item);
      final size = measure(text).ceilToDouble() + 8;
      var lane = -1;
      for (var candidate = 0; candidate < rows; candidate++) {
        if (_televisionFlights
            .where((flight) => flight.lane == candidate)
            .every(
              (flight) =>
                  (now - flight.item.timeMs) * pixelsPerSecond / 1000 -
                      flight.width >=
                  24,
            )) {
          lane = candidate;
          break;
        }
      }
      if (lane < 0) continue;
      _televisionFlights.add(
        DanmakuFlight(
          DanmakuItem(
            id: item.id,
            text: item.text,
            timeMs: now,
            repeatCount: item.repeatCount,
          ),
          text,
          lane,
          size,
          lifetimeMs: ((width + size) / pixelsPerSecond * 1000).ceil(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _televisionTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: IgnorePointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!constraints.hasBoundedWidth ||
                !constraints.hasBoundedHeight ||
                constraints.maxWidth <= 0 ||
                constraints.maxHeight <= 0) {
              return const SizedBox.shrink();
            }
            final aspect = widget.aspectRatio.isFinite && widget.aspectRatio > 0
                ? widget.aspectRatio
                : 16 / 9;
            final width = math.min(
              constraints.maxWidth,
              constraints.maxHeight * aspect,
            );
            final height = math.min(
              constraints.maxHeight,
              constraints.maxWidth / aspect,
            );
            final fontSize = widget.television
                ? 14.0
                : width < 600
                ? 12.0
                : 14.0;
            final lifetimeMs = widget.television ? 32000 : danmakuLifetimeMs;
            final topInset = widget.television ? 12.0 : 8.0;
            final scaler = MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.15);
            final rowHeight = scaler.scale(fontSize) * 1.5;
            final rows =
                ((height * (widget.television ? .18 : .38) - topInset) /
                        rowHeight)
                    .floor()
                    .clamp(0, widget.television ? 2 : 3);
            final style = TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(
                alpha: widget.television ? .55 : .62,
              ),
              height: 1.2,
              shadows: const [
                Shadow(
                  color: Color(0x66000000),
                  blurRadius: 1,
                  offset: Offset(0, .5),
                ),
              ],
            );
            return Center(
              child: SizedBox(
                width: width,
                height: height,
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: widget.controller,
                    builder: (context, _) {
                      final controller = widget.controller;
                      if (!controller.visible || rows == 0) {
                        _televisionTicker.stop();
                        _televisionLayout = null;
                        return const SizedBox.shrink();
                      }
                      double measure(String text) {
                        final painter = TextPainter(
                          text: TextSpan(text: text, style: style),
                          textDirection: TextDirection.ltr,
                          textScaler: scaler,
                          maxLines: 1,
                        )..layout();
                        final measured = painter.width;
                        painter.dispose();
                        return measured;
                      }

                      final layout = (
                        controller,
                        controller.dataRevision,
                        width,
                        rows,
                        lifetimeMs,
                        fontSize,
                        scaler,
                      );
                      if (widget.television) {
                        _updateTelevision(controller, width, rows, (
                          controller,
                          controller.timelineRevision,
                          width,
                          rows,
                          fontSize,
                          scaler,
                        ), measure);
                      } else {
                        _televisionTicker.stop();
                        _televisionLayout = null;
                      }
                      if (!widget.television && _layout != layout) {
                        _layout = layout;
                        _schedule = planDanmaku(
                          controller.items,
                          width: width,
                          rows: rows,
                          lifetimeMs: lifetimeMs,
                          measure: measure,
                        );
                      }
                      final flights = widget.television
                          ? _televisionFlights
                          : _schedule;
                      final position = widget.television
                          ? _televisionPositionMs
                          : controller.positionMs;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final flight in flights)
                            if (position >= flight.item.timeMs &&
                                position <
                                    flight.item.timeMs +
                                        (widget.television
                                            ? flight.lifetimeMs
                                            : lifetimeMs))
                              Positioned(
                                key: ValueKey('danmaku-item-${flight.item.id}'),
                                left: 0,
                                top: topInset + flight.lane * rowHeight,
                                width: flight.width,
                                height: rowHeight,
                                child: _DanmakuMotion(
                                  flight: flight,
                                  lifetimeMs: widget.television
                                      ? flight.lifetimeMs
                                      : lifetimeMs,
                                  width: width,
                                  positionMs: position,
                                  moving: controller.moving,
                                  rate: widget.television ? 1 : controller.rate,
                                  revision: controller.motionRevision,
                                  style: style,
                                  scaler: scaler,
                                ),
                              ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _DanmakuMotion extends StatefulWidget {
  const _DanmakuMotion({
    required this.flight,
    required this.lifetimeMs,
    required this.width,
    required this.positionMs,
    required this.moving,
    required this.rate,
    required this.revision,
    required this.style,
    required this.scaler,
  });
  final DanmakuFlight flight;
  final int lifetimeMs;
  final double width;
  final int positionMs;
  final bool moving;
  final double rate;
  final int revision;
  final TextStyle style;
  final TextScaler scaler;

  @override
  State<_DanmakuMotion> createState() => _DanmakuMotionState();
}

class _DanmakuMotionState extends State<_DanmakuMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_DanmakuMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lifetimeMs != widget.lifetimeMs ||
        oldWidget.revision != widget.revision ||
        oldWidget.width != widget.width ||
        oldWidget.flight.width != widget.flight.width ||
        oldWidget.flight.item.timeMs != widget.flight.item.timeMs) {
      _sync();
    }
  }

  void _sync() {
    _motion.stop();
    final elapsed = (widget.positionMs - widget.flight.item.timeMs).clamp(
      0,
      widget.lifetimeMs,
    );
    _motion.value = elapsed / widget.lifetimeMs;
    if (widget.moving && elapsed < widget.lifetimeMs) {
      _motion.animateTo(
        1,
        duration: Duration(
          microseconds: ((widget.lifetimeMs - elapsed) * 1000 / widget.rate)
              .round()
              .clamp(1, 86400000000),
        ),
        curve: Curves.linear,
      );
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _motion,
    child: RepaintBoundary(
      child: Text(
        widget.flight.text,
        style: widget.style,
        textScaler: widget.scaler,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        softWrap: false,
      ),
    ),
    builder: (context, child) => Transform.translate(
      key: ValueKey('danmaku-motion-${widget.flight.item.id}'),
      offset: Offset(
        widget.width - (widget.width + widget.flight.width) * _motion.value,
        0,
      ),
      child: child,
    ),
  );
}
