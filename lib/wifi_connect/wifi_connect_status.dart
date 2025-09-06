import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WifiStatus extends StatefulWidget {
  final Color? color;
  final double? size;

  const WifiStatus({Key? key, this.color, this.size}) : super(key: key);

  @override
  _WifiStatusState createState() => _WifiStatusState();
}

class _WifiStatusState extends State<WifiStatus> {
  static const platform = MethodChannel('wifi_settings');

  Timer? _timer;
  String _status = '확인 중...';
  int? _rssi;

  @override
  void initState() {
    super.initState();
    _checkStatus();

    // 주기적으로 WiFi 상태 확인 (3초마다)
    _timer = Timer.periodic(Duration(seconds: 3), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    final bool isConnected = await _isWifiConnected();
    if (isConnected) {
      final int? rssi = await _getWifiRssi();
      setState(() {
        _status = 'WiFi 연결됨';
        _rssi = rssi;
      });
    } else {
      setState(() {
        _status = 'WiFi 연결 안 됨';
        _rssi = null;
      });
    }
  }

  Future<bool> _isWifiConnected() async {
    try {
      final bool connected = await platform.invokeMethod('isWifiConnected');
      if (!connected) {
        _rssi = null;
      }

      return connected;
    } catch (e) {
      return false;
    }
  }

  Future<int?> _getWifiRssi() async {
    try {
      final int rssi = await platform.invokeMethod('getWifiRssi');
      return rssi;
    } catch (e) {
      return null;
    }
  }

  IconData _getSignalDescription(int? rssi) {
    if (rssi == null) return Icons.wifi_off;
    if (rssi >= -50) return Icons.wifi;
    if (rssi >= -60) return Icons.wifi_2_bar;
    if (rssi >= -70) return Icons.wifi_1_bar;
    if (rssi >= -80) return Icons.wifi_1_bar_rounded;
    return Icons.signal_wifi_0_bar;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      _getSignalDescription(_rssi),
      size: widget.size ?? 32,
      color: widget.color ?? const Color.fromARGB(255, 0, 31, 99),
    );
  }
}
