import 'dart:developer';

import 'package:flutter/services.dart';

class SecurityCheck {
  static const MethodChannel _channel = MethodChannel('security_check');

  /// 앱 실행 시 호출할 메서드
  /// 보안 위협이 감지되면 앱을 종료시킨다.
  static Future<void> run() async {
    try {
      final result = await _channel.invokeMethod('runSecurityChecks');
      if (result == true) {
        log("🔒 보안 위협 감지됨: 앱 종료 시도");
        await _terminateApp();
      } else{
        log("🔒 보안 위협 미감지");
      }
    } catch (e) {
      log('❗ 보안 체크 실패: $e');
    }
  }

  /// Android 네이티브 쪽에서 앱을 완전히 종료하는 메서드 호출
  static Future<void> _terminateApp() async {
    try {
      log("📴 앱 종료 요청: terminateApp 호출됨");
      await _channel.invokeMethod('terminateApp');
    } catch (e) {
      log('❗ 앱 종료 실패: $e');
    }
  }
}
