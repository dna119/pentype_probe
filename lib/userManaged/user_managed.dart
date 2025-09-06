import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pentype_probe_viewer/battery_status/battery_status.dart';
import 'package:pentype_probe_viewer/database/database.dart';
import 'package:pentype_probe_viewer/userManaged/add_new_user.dart';
import 'package:pentype_probe_viewer/wifi_connect/wifi_connect_status.dart';

import '../database/sessions.dart';
import 'edit_user.dart';

class UserManaged extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserManaged({super.key, required this.user});

  @override
  State<UserManaged> createState() => _UserManagedState();
}

class _UserManagedState extends State<UserManaged> {
  final userSessions = UserSessions();
  final dbHelper = DatabaseHelper();

  late List<Map<String, dynamic>> users;
  late bool usersIsInit;
  late String _version;

  void _getVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version; // 버전 정보
    });
  }

  void addNewUser() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(builder: (context) => AddNewUser()),
    )
        .then((_) {
      dbHelper.getUsers().then((List<Map<String, dynamic>> value) {
        setState(() {
          users = value;
          usersIsInit = true;
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _version = '';
    _getVersion();

    usersIsInit = false;

    dbHelper.getUsers().then((List<Map<String, dynamic>> value) {
      setState(() {
        users = value;
        usersIsInit = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        color: Color.fromARGB(255, 240, 240, 240),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: screenWidth * 0.1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: screenWidth * 0.06,
                    height: screenWidth * 0.06,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color.fromARGB(255, 0, 31, 99),
                        elevation: 5,
                      ),
                      child: Icon(
                        Icons.arrow_back_outlined,
                        size: screenWidth * 0.06,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Spacer(),
                  BatteryStatus(size: screenWidth * 0.05),
                  SizedBox(width: screenWidth * 0.025),
                  WifiStatus(size: screenWidth * 0.05),
                  SizedBox(width: screenWidth * 0.025),
                  SizedBox(
                    height: screenWidth * 0.06,
                    child: Image.asset("assets/images/logo.png"),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  color: Colors.grey,
                  width: screenWidth * 0.1,
                  height: screenWidth * 0.1,
                ),
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    widget.user["name"],
                    style: TextStyle(fontSize: screenWidth * 0.015),
                  ),
                ),
                SizedBox(
                  height: screenWidth * 0.015,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(),
                Container(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 31, 99),
                      shape: RoundedRectangleBorder(
                        // 모서리 라운드
                        borderRadius:
                            BorderRadius.circular(5), // 원하는 반지름 값 (예: 12)
                      ),
                    ),
                    onPressed: addNewUser,
                    child: Text(
                      "Add New User",
                      style: TextStyle(
                          fontSize: screenWidth * 0.015, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                child: Column(
                  children: [
                    Row(),
                    getUserListheader(screenWidth),
                    Expanded(
                      child: usersIsInit
                          ? ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: users.length, // 항목의 총 개수
                              itemBuilder: (context, index) {
                                return getUserListItem(users[index], index,
                                    screenWidth, screenWidth);
                              },
                            )
                          : CircularProgressIndicator(),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getUserListheader(screenWidth) {
    const Color backgourndColor = Color.fromARGB(255, 0, 31, 99);
    return Row(
      children: [
        Container(
          width: screenWidth * 0.05,
          height: screenWidth * 0.03,
          alignment: Alignment.center,
          color: backgourndColor,
          child: Text(
            "번 호",
            style:
                TextStyle(fontSize: screenWidth * 0.015, color: Colors.white),
          ),
        ),
        Container(
          width: screenWidth * 0.15,
          height: screenWidth * 0.03,
          alignment: Alignment.center,
          color: backgourndColor,
          child: Text(
            "사 용 자 명",
            style:
                TextStyle(fontSize: screenWidth * 0.015, color: Colors.white),
          ),
        ),
        Container(
          width: screenWidth * 0.15,
          height: screenWidth * 0.03,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
          color: backgourndColor,
          child: Text(
            "사 용 자 ID",
            style:
                TextStyle(fontSize: screenWidth * 0.015, color: Colors.white),
          ),
        ),
        Container(
          width: screenWidth * 0.1,
          height: screenWidth * 0.03,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
          color: backgourndColor,
          child: Text(
            "권  한",
            style:
                TextStyle(fontSize: screenWidth * 0.015, color: Colors.white),
          ),
        ),
        Container(
          width: screenWidth * 0.1,
          height: screenWidth * 0.03,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
          color: backgourndColor,
          child: Text(
            "활 성 화",
            style:
                TextStyle(fontSize: screenWidth * 0.015, color: Colors.white),
          ),
        ),
        Container(
          width: screenWidth * 0.2,
          height: screenWidth * 0.03,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
          color: backgourndColor,
          child: Text(
            "등 록 일 자",
            style:
                TextStyle(fontSize: screenWidth * 0.015, color: Colors.white),
          ),
        ),
        Container(
          width: screenWidth * 0.2,
          height: screenWidth * 0.03,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
          color: backgourndColor,
          child: Text(
            "정 보 수 정",
            style:
                TextStyle(fontSize: screenWidth * 0.015, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget getUserListItem(
      Map<String, dynamic> user, int index, screenHeight, screenWidth) {
    Color backgourndColor =
        index % 2 == 0 ? Color.fromARGB(255, 200, 200, 200) : Colors.white;
    return Row(
      children: [
        buildInkContainer(
          width: screenWidth * 0.05,
          height: screenWidth * 0.04,
          padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.01),
          color: backgourndColor,
          child: Text(
            "$index",
            style: TextStyle(fontSize: screenWidth * 0.015),
          ),
        ),
        buildInkContainer(
          width: screenWidth * 0.15,
          height: screenWidth * 0.04,
          padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.01),
          color: backgourndColor,
          child: Text(
            user["name"],
            style: TextStyle(fontSize: screenWidth * 0.015),
          ),
        ),
        buildInkContainer(
          width: screenWidth * 0.15,
          height: screenWidth * 0.04,
          padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.01),
          color: backgourndColor,
          child: Text(
            user["user_id"],
            style: TextStyle(fontSize: screenWidth * 0.015),
          ),
        ),
        buildInkContainer(
          width: screenWidth * 0.1,
          height: screenWidth * 0.04,
          padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.01),
          color: backgourndColor,
          child: Text(
            user["authority"],
            style: TextStyle(fontSize: screenWidth * 0.015),
          ),
        ),
        buildInkContainer(
          width: screenWidth * 0.1,
          height: screenWidth * 0.04,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
          color: backgourndColor,
          child: Text(
            user["is_locked"] == 0 ? "O" : "X",
            style: TextStyle(fontSize: screenWidth * 0.015),
          ),
        ),
        buildInkContainer(
          width: screenWidth * 0.2,
          height: screenWidth * 0.04,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
          color: backgourndColor,
          child: Text(
            formatDateTimeSimple(user["created_at"]),
            style: TextStyle(fontSize: screenWidth * 0.015),
          ),
        ),
        buildInkContainer(
          width: screenWidth * 0.2,
          height: screenWidth * 0.04,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
          color: backgourndColor,
          child: SizedBox(
            width: double.infinity, // 부모 Container가 꽉 차게
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 0, 31, 99), // 배경색 변경
                shape: RoundedRectangleBorder(
                  // 모서리 라운드
                  borderRadius: BorderRadius.circular(5), // 원하는 반지름 값 (예: 12)
                ),
              ),
              onPressed: () async {
                final currentUser = await userSessions.getUser();
                final updated = await showUserEditDialog(context, user, currentUser?['id']);
                if (updated) {
                  final newUsers = await dbHelper.getUsers();
                  setState(() {
                    users = newUsers;
                  });
                }
              },
              child: Text(
                "정보수정",
                style: TextStyle(
                  fontSize: screenWidth * 0.015,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildInkContainer({
    required double width,
    required double height,
    required EdgeInsets padding,
    required Widget child,
    required Color color,
  }) {
    return Ink(
      width: width,
      height: height,
      padding: padding,
      color: color,
      child: Center(child: child),
    );
  }

  String formatDateTimeSimple(String isoString) {
    return isoString.substring(0, 19).replaceFirst('T', ' ');
  }
}
