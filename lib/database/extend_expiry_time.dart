import 'package:flutter/material.dart';
import 'package:pentype_probe_viewer/database/sessions.dart';

class ExtendExpiryTime extends StatefulWidget {
  @override
  State<ExtendExpiryTime> createState() => _ExtendExpiryTimeState();
}

class _ExtendExpiryTimeState extends State<ExtendExpiryTime> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    return AlertDialog(
      content: Text("로그인 시간을 연장하시겠습니까?"),
      actions: [
        InkWell(
          onTap: () {
            Navigator.pop(context, false);
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
        InkWell(
          onTap: () async {
            Navigator.pop(context, true);
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
      ],
    );
  }
}
