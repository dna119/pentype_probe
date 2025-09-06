/*
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KekManager {
  static const _kekKeyName = 'app_kek';
  static const _channel = MethodChannel('kek_channel'); // MethodChannel 추가

  KekManager();

  /// KEK 가져오기 (없으면 생성)
  Future<String> getOrCreateKek() async {
    final String kek = await _channel.invokeMethod('getOrCreateKek');
    return kek;
  }

  Future<void> rotateKek() async {
    await _channel.invokeMethod('rotateKek');
  }

  Future<void> deleteKek() async {
    await _channel.invokeMethod('deleteKek');
  }

  /// 내부: 안전한 256비트 키 생성
  String _generateSecureKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }
}
 */