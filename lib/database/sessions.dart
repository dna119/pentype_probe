import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pentype_probe_viewer/config.dart';
import 'package:pentype_probe_viewer/database/database.dart';
import 'package:pentype_probe_viewer/database/passwordChange.dart';
import 'package:pentype_probe_viewer/login/user_session_status.dart';

import 'extend_expiry_time.dart';

class UserSessions {
  final dbHelper = DatabaseHelper();
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  late Timer _timer;

  DateTime? expiryTime;
  Duration? remainedTime;

  bool expiryTimeIsWarning = false;

  Future<void> userExpiryTime(
      BuildContext context, VoidCallback eachTimes) async {
    debugPrint("Fetching expiry time...");
    DateTime? expiryTimeTemp = await getExpiryTime();

    if (expiryTimeTemp == null) {
      debugPrint("Expiry time is null. Logging out.");
      logout(context);
      return;
    }

    expiryTime = expiryTimeTemp;
    debugPrint("Expiry time set to: $expiryTime");

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      remainedTime = expiryTime!.difference(DateTime.now());

      if (remainedTime!.isNegative) {
        debugPrint("세션 만료됨. 로그아웃 및 앱 종료.");
        remainedTime = Duration.zero;
        logout(context); // 앱 종료
        timer.cancel(); // 타이머 종료
        return;
      }

      debugPrint("남은 시간: ${remainedTime!.inSeconds}초");

      if (!expiryTimeIsWarning &&
          (remainedTime!.inSeconds <= USER_EXPIRY_TIME_WARNING * 60)) {
        debugPrint("세션 만료 경고. 다이얼로그 표시.");

        expiryTimeIsWarning = true;

        showDialog(
          context: context,
          builder: (BuildContext context) => ExtendExpiryTime(),
        ).then(
              (result) async {
            debugPrint("다이얼로그 닫힘. 결과: $result");

            if (result) {
              expiryTimeIsWarning = false;

              debugPrint("세션 유효성 확인 중...");
              if (!await isSessionValid()) {
                debugPrint("세션이 유효하지 않음. 앱 종료.");
                logout(context); // 앱 종료
                return;
              }

              debugPrint("세션 연장 중...");
              extendExpiryTime();

              DateTime? expiryTimeTemp = await getExpiryTime();
              if (expiryTimeTemp == null) {
                debugPrint("새 만료 시간 가져오기 실패. 앱 종료.");
                logout(context); // 앱 종료
                return;
              }

              expiryTime = expiryTimeTemp;
              debugPrint("새 만료 시간: $expiryTime");
            }
          },
        );
      }

      eachTimes();
    });
  }


  Future<void> ExtendUserExpiryTime(BuildContext context) async {
    if (!await isSessionValid()) {
      logout(context);
    }
    extendExpiryTime();
    DateTime? expiryTimeTemp = await getExpiryTime();
    if (expiryTimeTemp == null) {
      logout(context);
    }
    expiryTime = expiryTimeTemp!;
  }

  Future<UserSessionStatus> login(
      String userId, String password, BuildContext context) async {
    final db = await dbHelper.database;

    // 사용자 조회
    final List<Map<String, dynamic>> users = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (users.isEmpty) return UserSessionStatus.fail;

    final user = users.first;

    // salt 기반 해시 계산
    final salt = user['salt'] ?? '';
    final hashedInputPassword = hashPassword(password, salt);

    if (user['password'] == hashedInputPassword) {
      // 잠긴 계정 확인
      if (user['is_locked'] == 1) {
        return UserSessionStatus.userLocked;
      }
      // 로그인 성공: 시도 횟수 초기화
      await db.update(
        'users',
        {
          'login_attempts': 0,
        },
        where: 'id = ?',
        whereArgs: [user['id']],
      );
      final token = generateSecureToken();
      dev.log("로그인 계정: $userId");
      dev.log("로그인 토큰: $token");
      dev.log("로그인한 시간: ${DateTime.now()}");
      dev.log("로그인 만료시간: ${DateTime.now().add(const Duration(minutes: USER_EXPIRY_TIME)).toIso8601String()}");
      await _storage.write(key: 'login_token', value: token);
      await _storage.write(key: 'loggedInUserId', value: userId);
      await _storage.write(
          key: 'expiryTime',
          value: DateTime.now()
              .add(const Duration(minutes: USER_EXPIRY_TIME))
              .toIso8601String());

      // 첫 로그인 시 비밀번호 변경 유도
      if (user["updated_at"] == null) {
        if (await PasswordChangeDialog.show(context, user)) {
          return UserSessionStatus.passwordExchanged;
        }
        return UserSessionStatus.passwordExchangedFail;
      }
      return UserSessionStatus.success;
    } else {
      // 로그인 실패 시 시도 횟수 증가 및 잠금 여부 결정
      int newAttempts = (user['login_attempts'] ?? 0) + 1;

      await db.update(
        'users',
        {
          'login_attempts': newAttempts,
          'is_locked': newAttempts >= 5 ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [user['id']],
      );

      if (newAttempts >= 5) {
        return UserSessionStatus.userLocked;
      }

      return UserSessionStatus.fail;
    }
  }

  Future<int> getUserAtempts(String userId) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> users = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (users.isEmpty) return 0;

    final user = users.first;
    return user['login_attempts'] ?? 0;
  }

  Future<bool> isSessionValid() async {
    String? expiry = await _storage.read(key: 'expiryTime');
    dev.log("$expiry");
    if (expiry == null) return false;

    DateTime expiryDate = DateTime.parse(expiry);

    return DateTime.now().isBefore(expiryDate);
  }

  Future<void> checkessionValidAndPush(
      context, MaterialPageRoute materialPageRout) async {
    String? expiry = await _storage.read(key: 'expiryTime');

    if (expiry == null) {
      logout(context);
      return;
    }
    DateTime expiryDate = DateTime.parse(expiry);

    if (DateTime.now().isAfter(expiryDate)) {
      logout(context);
      return;
    }

    Navigator.of(context).push(
      materialPageRout,
    );
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      dev.log("getUser: DB 접근 시작");

      final db = await dbHelper.database;
      dev.log("getUser: DB 객체 획득 완료");

      String? userId = await _storage.read(key: "loggedInUserId");
      dev.log("getUser: 로그인된 사용자 ID = $userId");

      if (userId == null || userId.isEmpty) {
        dev.log("getUser: 사용자 ID가 null 또는 empty");
        return null;
      }

      final result = await db.query(
        'users',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      dev.log("getUser: DB 쿼리 결과: $result");

      if (result.isEmpty) {
        dev.log("getUser: 사용자 정보를 찾을 수 없음");
        return null;
      }

      return result[0];
    } catch (e, stack) {
      dev.log("getUser: 예외 발생: $e\n$stack");
      return null;
    }
  }


  // 로그아웃 로직
  Future<void> logout(BuildContext context) async {
    await _storage.delete(key: "loggedInUserId");
    await _storage.delete(key: "expiryTime");

    debugPrint("앱을 종료합니다.");

    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0); // iOS: 강제 종료, 주의 필요
    }
  }

  Future<DateTime?> getExpiryTime() async {
    String? expiryTimeString = await _storage.read(key: 'expiryTime');
    if (expiryTimeString == null) {
      return null;
    }
    return DateTime.parse(expiryTimeString);
  }

  Future<void> extendExpiryTime() async {
    await _storage.write(
        key: 'expiryTime',
        value: DateTime.now()
            .add(const Duration(minutes: USER_EXPIRY_TIME))
            .toIso8601String());
  }

  void dispose() {
    _timer.cancel();
  }

  String generateSecureToken([int length = 32]) {
    final rand = Random.secure();
    final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
