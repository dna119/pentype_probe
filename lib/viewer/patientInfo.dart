import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pentype_probe_viewer/database/sessions.dart';
import 'package:pentype_probe_viewer/viewer/viewer.dart';

class PatientInfo extends StatefulWidget {
  PatientInfo({super.key});

  @override
  State<PatientInfo> createState() => _PatientInfoState();
}

class _PatientInfoState extends State<PatientInfo> {
  static const _channel = MethodChannel('ffmpeg_channel');

  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController patientCodeController = TextEditingController();
  final TextEditingController patientBirthYearController =
      TextEditingController();
  final TextEditingController patientBirthMonthController =
      TextEditingController();
  final TextEditingController patientBirthDateController =
      TextEditingController();

  final FocusNode patientBirthFocusNode = FocusNode();

  late DateTime patietnBirth;

  final _userSessions = UserSessions();

  @override
  void initState() {
    super.initState();

    patietnBirth = DateTime.now();
  }

  @override
  void dispose() {
    patientBirthYearController.dispose();
    patientBirthMonthController.dispose();
    patientBirthDateController.dispose();
    patientNameController.dispose();
    patientCodeController.dispose();
    patientBirthFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return AlertDialog(
      title: Text(
        "환자 정보 입력",
        style: TextStyle(fontSize: screenWidth * 0.02),
      ),
      content: Container(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    "코드:  ",
                    style: TextStyle(fontSize: screenWidth * 0.015),
                  ),
                  Expanded(
                    child: TextField(
                      controller: patientCodeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(fontSize: screenWidth * 0.015),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                splashColor: Colors.grey.withOpacity(0.3),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.01),
                  child: Text(
                    textAlign: TextAlign.center,
                    '취소',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () async {
                  Map<String, dynamic>? user = await _userSessions.getUser();
                  if (user == null) {
                    _userSessions.logout(context);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Viewer(
                        user: user!,
                        patientID: "",
                      ),
                    ),
                  ).then((_) async {
                    await _channel.invokeMethod('stopStreaming');
                    log("Viewer Pop");
                    Navigator.pop(context);
                  });
                },

                splashColor: Colors.grey.withOpacity(0.3),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.01),
                  child: Text(
                    textAlign: TextAlign.center,
                    '건너뛰기',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () async {
                  Map<String, dynamic>? user = await _userSessions.getUser();
                  if (user == null) {
                    _userSessions.logout(context);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Viewer(
                        user: user!,
                        patientID: patientCodeController.text,
                      ),
                    ),
                  ).then((_) {
                    Navigator.pop(context);
                  });
                },
                splashColor: Colors.grey.withOpacity(0.3),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.01),
                  child: Text(
                    textAlign: TextAlign.center,
                    '확인',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
