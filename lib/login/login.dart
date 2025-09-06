import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pentype_probe_viewer/database/sessions.dart';
import 'package:pentype_probe_viewer/information/software_information.dart';
import 'package:pentype_probe_viewer/login/user_session_status.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final userSessions = UserSessions();
  final TextEditingController _idTextEditingController =
      TextEditingController();
  final TextEditingController _pwTextEditingController =
      TextEditingController();

  final FocusNode _idTextFieldFocusNode = FocusNode();
  final FocusNode _pwTextFieldFocusNode = FocusNode();

  late bool _isButtonEnabled;

  late String _loginMessage;
  late DateTime? _lastBackPressed;

  void _checkInput() {
    setState(() {
      _isButtonEnabled = _idTextEditingController.text.trim().isNotEmpty &&
          _pwTextEditingController.text.trim().isNotEmpty;
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    log("_onWillPop");
    log("_lastBackPressed: $_lastBackPressed");
    log("_onWillPop");
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

  Future<void> _login() async {
    log("Login: _login");
    _idTextFieldFocusNode.unfocus();
    _pwTextFieldFocusNode.unfocus();

    final UserSessionStatus loginStatus = await userSessions.login(
        _idTextEditingController.text, _pwTextEditingController.text, context);
    log("$loginStatus");
    if (loginStatus == UserSessionStatus.success) {
      Navigator.pop(context);
    } else if (loginStatus == UserSessionStatus.fail) {
      final int userAtempts =
          await userSessions.getUserAtempts(_idTextEditingController.text);
      setState(() {
        log("setState");
        _loginMessage = "${loginStatus.message}(${userAtempts}/5)";
      });
    } else {
      _idTextEditingController.text = "";
      _pwTextEditingController.text = "";
      setState(() {
        _loginMessage = loginStatus.message;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _isButtonEnabled = false;

    _loginMessage = "";

    _idTextEditingController.addListener(_checkInput);
    _pwTextEditingController.addListener(_checkInput);
  }

  @override
  void dispose() {
    super.dispose();

    _idTextEditingController.dispose();
    _pwTextEditingController.dispose();

    _idTextFieldFocusNode.dispose();
    _pwTextFieldFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: GestureDetector(
          onTap: () {
            _idTextFieldFocusNode.unfocus();
            _pwTextFieldFocusNode.unfocus();
          },
          child: SizedBox.expand(
            child: SingleChildScrollView(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                    ),
                    Container(
                      height: 150,
                      child: Image.asset("assets/images/logo.png"),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Container(
                      height: 100,
                      width: screenWidth * 0.35,
                      alignment: Alignment.center,
                      child: TextField(
                        focusNode: _idTextFieldFocusNode,
                        controller: _idTextEditingController,
                        style: TextStyle(fontSize: screenHeight * 0.04),
                        textInputAction: TextInputAction.next,
                        onSubmitted: (value) {
                          FocusScope.of(context)
                              .requestFocus(_pwTextFieldFocusNode);
                        },
                        decoration: InputDecoration(
                          labelText: "ID",
                          labelStyle: TextStyle(fontSize: screenHeight * 0.04),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Container(
                      height: 100,
                      width: screenWidth * 0.35,
                      alignment: Alignment.center,
                      child: TextField(
                        obscureText: true,
                        focusNode: _pwTextFieldFocusNode,
                        controller: _pwTextEditingController,
                        style: TextStyle(fontSize: screenHeight * 0.04),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(fontSize: screenHeight * 0.04),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      _loginMessage,
                      style: TextStyle(
                          fontSize: screenHeight * 0.025, color: Colors.red),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Container(
                      height: 75,
                      width: screenWidth * 0.35,
                      child: ElevatedButton(
                        onPressed: _isButtonEnabled ? _login : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isButtonEnabled
                              ? const Color.fromARGB(255, 0, 31, 99)
                              : Colors.grey, // 배경색
                          foregroundColor: Colors.white, // 텍스트 색상
                          elevation: 5, // 버튼의 그림자 높이
                        ),
                        child: Text(
                          "Login",
                          style: TextStyle(
                              fontSize: screenHeight * 0.04,
                              color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: Padding(
          padding: EdgeInsets.all(screenWidth * 0.02),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SoftwareInformation(isLogin: false,)),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            highlightElevation: 0,
            splashColor: Colors.transparent,
            hoverElevation: 0,
            tooltip: '다음 화면으로',
            child: Icon(
              Icons.info_outline,
              size: screenWidth * 0.075,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }
}
