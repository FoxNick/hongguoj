import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_layout.dart';

class PlayerDeviceStatus extends StatefulWidget {
  const PlayerDeviceStatus({super.key, required this.visible});

  final bool visible;

  @override
  State<PlayerDeviceStatus> createState() => _PlayerDeviceStatusState();
}

class _PlayerDeviceStatusState extends State<PlayerDeviceStatus>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _now = DateTime.now();
  int? _percent;
  bool _charging = false;
  bool _resumed = true;
  int _generation = 0;

  bool get _active => mounted && widget.visible && _resumed;

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    _resumed =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    _restart();
  }

  @override
  void didUpdateWidget(PlayerDeviceStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      _restart();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _restart();
  }

  void _restart() {
    _generation++;
    _timer?.cancel();
    if (_active) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    if (!_active) return;
    final ticket = _generation;
    final now = DateTime.now();
    setState(() => _now = now);
    final untilMinute = 60000 - now.second * 1000 - now.millisecond;
    _timer = Timer(
      Duration(milliseconds: untilMinute.clamp(1, 15000).toInt()),
      () => unawaited(_refresh()),
    );
    if (defaultTargetPlatform != TargetPlatform.android) return;
    int? percent;
    var charging = false;
    try {
      final data = await AppDevice.channel
          .invokeMapMethod<String, dynamic>('batteryStatus')
          .timeout(const Duration(seconds: 2));
      final value = data?['percent'];
      if (value is num && value.isFinite && value >= 0 && value <= 100) {
        percent = value.round();
        charging = data?['charging'] == true;
      }
    } catch (_) {}
    if (!_active || ticket != _generation) return;
    if (_percent != percent || _charging != charging) {
      setState(() {
        _percent = percent;
        _charging = charging;
      });
    }
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time =
        '${_now.hour.toString().padLeft(2, '0')}:'
        '${_now.minute.toString().padLeft(2, '0')}';
    final android = defaultTargetPlatform == TargetPlatform.android;
    final batteryLabel = _percent == null ? '电量暂不可用' : '电量 $_percent%';
    return Semantics(
      label:
          '当前时间 $time${android ? '，$batteryLabel${_charging ? '，正在充电' : ''}' : ''}',
      child: ExcludeSemantics(
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  key: const ValueKey('player-current-time'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (android) ...[
                  const SizedBox(width: 10),
                  Icon(
                    _percent == null
                        ? Icons.battery_unknown_rounded
                        : _charging
                        ? Icons.battery_charging_full_rounded
                        : _percent! <= 15
                        ? Icons.battery_alert_rounded
                        : Icons.battery_std_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _percent == null ? '--%' : '$_percent%',
                    key: const ValueKey('player-battery-percent'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
