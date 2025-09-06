import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pentype_probe_viewer/battery_status/battery_status.dart';
import 'package:pentype_probe_viewer/information/software_information.dart';
import 'package:pentype_probe_viewer/savedData/patient_list.dart';
import 'package:pentype_probe_viewer/userManaged/user_managed.dart';
import 'package:pentype_probe_viewer/viewer/patientInfo.dart';
import 'package:pentype_probe_viewer/wifi_connect/wifi_connect_status.dart';

import 'database/sessions.dart';

class Home extends StatefulWidget {
  final Map<String, dynamic>? user;

  const Home({super.key, required this.user});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  bool _hasOpenedWifiSettings = false;
  final _userSessions = UserSessions();
  DateTime? _lastBackPressed;

  bool connectManaged() {
    // 권한 확인 로직 필요
    _userSessions.checkessionValidAndPush(
      context,
      MaterialPageRoute(builder: (context) => UserManaged(user: widget.user!)),
    );
    return true;
  }

  Future<bool> _onWillPop() async {
    log("_onWillPop");
    log("_lastBackPressed: $_lastBackPressed");
    log("_onWillPop");
    final now = DateTime.now();

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > Duration(seconds: 2)) {
      _lastBackPressed = now;
      Fluttertoast.showToast(
        msg: '뒤로 버튼을 한 번 더 누르면 종료됩니다',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      return Future.value(false);
    }

    // 안드로이드에서만 동작하도록 설정
    if (Platform.isAndroid) {
      // 앱 종료
      SystemNavigator.pop(); // 또는 exit(0) 사용 가능 (비권장)
    }

    return Future.value(true);
  }

  Completer<bool>? _wifiConnectCompleter;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_hasOpenedWifiSettings && state == AppLifecycleState.resumed) {
      _hasOpenedWifiSettings = false;
      _tryReconnectToCam();
    }
  }

  Future<bool> connectWifi() async {
    const platform = MethodChannel('wifi_settings');
    const camChannel = MethodChannel('battery_channel');

    try {
      // Wi-Fi 설정 화면 실행
      await platform.invokeMethod('openWiFiSettings');

      // 빈 화면을 푸시하고, 사용자가 뒤로 오면 reconnect 시도
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _WifiReturnWaitScreen(),
        ),
      );

      // result == true일 경우 reconnect 시도
      const int maxRetries = 5;
      const Duration retryInterval = Duration(seconds: 2);

      for (int i = 0; i < maxRetries; i++) {
        try {
          final int result = await camChannel.invokeMethod('reconnectToCam');
          log("[reconnectToCam] 재시도 ${i + 1}회 결과: $result");
          if (result == 0) {
            log("카메라 연결 성공");
            return true;
          }
        } catch (e) {
          log("카메라 연결 예외: $e");
        }
        await Future.delayed(retryInterval);
      }

      log("카메라 연결 실패");
      return false;
    } catch (e) {
      log("Wi-Fi 설정 화면 호출 실패: $e");
      return false;
    }
  }

  Future<void> _tryReconnectToCam() async {
    log("_tryReconnectToCam");
    const camChannel = MethodChannel('battery_channel');

    for (int i = 0; i < 5; i++) {
      try {
        final int result = await camChannel.invokeMethod('reconnectToCam');
        log("[재시도 ${i + 1}] reconnectToCam result: $result");

        if (result == 0) {
          log("카메라 연결 성공");
          _wifiConnectCompleter?.complete(true);
          _wifiConnectCompleter = null;
          return;
        }
      } catch (e) {
        log("카메라 연결 예외: $e");
      }

      await Future.delayed(Duration(seconds: 2));
    }

    log("카메라 연결 실패");
    _wifiConnectCompleter?.complete(false);
    _wifiConnectCompleter = null;
  }

  Future<void> connectView() async {
    // 연결 확인 로직 필요

    // 권한 확인 로직 필요
    if (!await _userSessions.isSessionValid()) {
      _userSessions.logout(context);
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) => PatientInfo(),
    );
    /*
    _userSessions.checkessionValidAndPush(
      context,
      MaterialPageRoute(builder: (context) => Viewer(user: widget.user!)),
    );*/
    return;
  }

  bool connectSaveData() {
    // 연결 확인 로직 필요

    // 권한 확인 로직 필요

    _userSessions.checkessionValidAndPush(
      context,
      MaterialPageRoute(builder: (context) => PatientList(user: widget.user!)),
    );
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _userSessions.userExpiryTime(context, () => setState(() {}));
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _userSessions.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          color: Color.fromARGB(255, 240, 240, 240),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: screenHeight * 0.05,
              ),
              Container(
                height: screenHeight * 0.1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      child: Row(
                        children: [
                          Text(
                            widget.user!["name"],
                            style: TextStyle(fontSize: screenWidth * 0.03),
                          ),
                          SizedBox(
                            width: screenWidth * 0.01,
                          ),
                          Text(
                            _userSessions.remainedTime == null
                                ? "--:--"
                                : "${(_userSessions.remainedTime!.inMinutes).toString().padLeft(2, '0')}:"
                                    "${(_userSessions.remainedTime!.inSeconds % 60).toString().padLeft(2, '0')}",
                            style: TextStyle(fontSize: screenWidth * 0.03),
                          ),
                          SizedBox(
                            width: screenWidth * 0.01,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _userSessions.logout(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    screenWidth * 0.01), // 원하는 반지름 값 설정
                              ),
                            ),
                            child: Text(
                              "로그아웃",
                              style: TextStyle(
                                  fontSize: screenWidth * 0.02,
                                  color: Colors.black),
                            ),
                          ),
                          SizedBox(
                            width: screenWidth * 0.01,
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                _userSessions.ExtendUserExpiryTime(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    screenWidth * 0.01), // 원하는 반지름 값 설정
                              ),
                            ),
                            child: Text(
                              "시간 연장",
                              style: TextStyle(
                                  fontSize: screenWidth * 0.02,
                                  color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    BatteryStatus(size: screenWidth * 0.05),
                    SizedBox(width: screenWidth * 0.025),
                    WifiStatus(size: screenWidth * 0.05),
                    SizedBox(width: screenWidth * 0.025),
                    Image.asset("assets/images/logo.png")
                  ],
                ),
              ),
              SizedBox(
                height: screenHeight * 0.025,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(),
                  Container(
                    width: screenHeight * 0.3,
                    height: screenHeight * 0.075,
                    child: widget.user!["authority"] == "ADMIN"
                        ? ElevatedButton(
                            onPressed: connectManaged,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 31, 99),
                              foregroundColor: Colors.white, // 텍스트 색상
                              elevation: 5, // 버튼의 그림자 높이
                            ),
                            child: Text(
                              "관리자 페이지",
                              style: TextStyle(fontSize: screenHeight * 0.03),
                            ),
                          )
                        : null,
                  )
                ],
              ),
              Expanded(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: screenHeight * 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        width: screenHeight * 0.3,
                        height: screenHeight * 0.3,
                        child: ElevatedButton(
                          onPressed: connectWifi,
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(screenHeight * 0.02),
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 31, 99),
                              foregroundColor: Colors.white,
                              // 텍스트 색상
                              elevation: 5,
                              // 버튼의 그림자 높이
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      screenHeight * 0.03))),
                          child: Column(
                            children: [
                              Text(
                                "와이파이 연결",
                                style: TextStyle(fontSize: screenHeight * 0.03),
                              ),
                              Icon(
                                Icons.wifi,
                                size: screenHeight * 0.20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: screenHeight * 0.3,
                        height: screenHeight * 0.3,
                        child: ElevatedButton(
                          onPressed: connectView,
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(screenHeight * 0.02),
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 31, 99),
                              foregroundColor: Colors.white,
                              // 텍스트 색상
                              elevation: 5,
                              // 버튼의 그림자 높이
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      screenHeight * 0.03))),
                          child: Column(
                            children: [
                              Text(
                                "실시간 뷰어",
                                style: TextStyle(fontSize: screenHeight * 0.03),
                              ),
                              Icon(
                                Icons.video_collection_outlined,
                                size: screenHeight * 0.20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: screenHeight * 0.3,
                        height: screenHeight * 0.3,
                        child: ElevatedButton(
                          onPressed: connectSaveData,
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(screenHeight * 0.02),
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 31, 99),
                              foregroundColor: Colors.white,
                              // 텍스트 색상
                              elevation: 5,
                              // 버튼의 그림자 높이
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      screenHeight * 0.03))),
                          child: Column(
                            children: [
                              Text(
                                "저장된 파일",
                                style: TextStyle(fontSize: screenHeight * 0.03),
                              ),
                              Icon(
                                Icons.save_outlined,
                                size: screenHeight * 0.20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: screenHeight * 0.15,
              ),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: EdgeInsets.all(screenWidth * 0.02),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SoftwareInformation()),
              );
            },
            child: Icon(
              Icons.info_outline,
              size: screenWidth * 0.075,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            highlightElevation: 0,
            splashColor: Colors.transparent,
            hoverElevation: 0,
            tooltip: '다음 화면으로',
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }
}


class _WifiReturnWaitScreen extends StatefulWidget {
  @override
  State<_WifiReturnWaitScreen> createState() => _WifiReturnWaitScreenState();
}

class _WifiReturnWaitScreenState extends State<_WifiReturnWaitScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Navigator.pop(context, true); // 설정 복귀 감지되면 pop
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 안보이게 해도 됨
      body: Center(
        child: Text(
          "Wi-Fi 설정에서 복귀 중...",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
