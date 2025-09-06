import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pentype_probe_viewer/database/sessions.dart';
import 'package:pentype_probe_viewer/home.dart';
import 'package:pentype_probe_viewer/login/login.dart';
import 'package:pentype_probe_viewer/security_check.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 시스템 UI 및 화면 방향 설정
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 위치 권한 요청
  await _requestLocationPermission();

  // 보안 체크 실행
  // 잠깐 대기 후 보안 체크 실행
  Future.delayed(Duration(seconds: 5), () async {
    await SecurityCheck.run();
  });

  // 앱 실행
  runApp(MaterialApp(
    home: const MyApp(),
    navigatorObservers: [routeObserver],
  ));
}

Future<void> _requestLocationPermission() async {
  final status = await Permission.location.status;
  if (!status.isGranted) {
    await Permission.location.request();
  }
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with RouteAware {
  final _userSessions = UserSessions();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _runFunction() async {
    final isValid = await _userSessions.isSessionValid();
    log("isValid: $isValid");

    Future.microtask(() async {
      try {
        if (!isValid) {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
        } else {
          log("mounted: $mounted");

          Map<String, dynamic>? user = await _userSessions.getUser();
          log('User: $user');

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => Home(user: user),
              ),
            );
          }
        }
      } catch (e, stack) {
        log("runFunction 내부 오류: $e\n$stack");
      }
    });
  }

  void _startFunction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const Login()),
        );
      }
    });
  }

  @override
  void didPush() {
    super.didPush();
    _startFunction();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _runFunction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          log("tap");
          _runFunction();
        },
        child: Container(
          alignment: Alignment.center,
          height: double.infinity,
          child: Container(
            alignment: Alignment.center,
            height: 150,
            child: Image.asset("assets/images/logo.png"),
          ),
        ),
      ),
    );
  }
}

const platform = MethodChannel('secure_storage_channel');
