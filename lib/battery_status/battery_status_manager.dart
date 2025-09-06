import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class BatteryStatusManager {
  static final BatteryStatusManager _instance = BatteryStatusManager._internal();
  factory BatteryStatusManager() => _instance;
  BatteryStatusManager._internal();

  static const _batteryRequestChannel = MethodChannel('battery_channel');
  static const _batteryStatusChannel = MethodChannel('battery_status_channel');

  final ValueNotifier<int> batteryLevel = ValueNotifier<int>(-1);

  Timer? _pollingTimer;
  Timer? _timeoutTimer;

  void initialize() {
    _batteryStatusChannel.setMethodCallHandler(_methodHandler);

    _pollingTimer ??= Timer.periodic(const Duration(seconds: 2), (_) {
      _batteryRequestChannel.invokeMethod('requestBatteryStatus');
      _startTimeout(); // 매 요청마다 타임아웃 타이머 리셋
    });
  }

  void _updateBatteryLevel(int newLevel) {
    if (batteryLevel.value != newLevel) {
      batteryLevel.value = newLevel;
    } else {
      batteryLevel.notifyListeners(); // 동일해도 강제 반영
    }
  }

  Future<void> _methodHandler(MethodCall call) async {
    if (call.method == "onBatteryLevel") {
      final dynamic raw = call.arguments;
      log("[BatteryStatusManager] Raw battery level: $raw (${raw.runtimeType})");

      final int newLevel = raw is int ? raw : int.tryParse(raw.toString()) ?? -99;

      _timeoutTimer?.cancel();
      _updateBatteryLevel(newLevel);
    }
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      log("[BatteryStatusManager] 응답 없음 → level -1 전송");
      _updateBatteryLevel(-1);  // ✅ 여기도 통일
    });
  }

  void dispose() {
    _pollingTimer?.cancel();
    _timeoutTimer?.cancel();
    _pollingTimer = null;
    _timeoutTimer = null;
  }
}
