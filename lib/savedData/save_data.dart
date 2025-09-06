import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pentype_probe_viewer/battery_status/battery_status.dart';
import 'package:pentype_probe_viewer/database/database.dart';
import 'package:pentype_probe_viewer/database/dek_rsa_manager.dart';
import 'package:pentype_probe_viewer/database/sessions.dart';
import 'package:pentype_probe_viewer/information/software_information.dart';
import 'package:pentype_probe_viewer/savedData/image_viwer.dart';
import 'package:pentype_probe_viewer/savedData/video_viewer.dart';
import 'package:pentype_probe_viewer/storage/storage_usage.dart';
import 'package:pentype_probe_viewer/wifi_connect/wifi_connect_status.dart';

class SaveData extends StatefulWidget {
  final Map<String, dynamic> user;
  final String? patientHash;

  const SaveData({super.key, required this.user, required this.patientHash});

  @override
  State<SaveData> createState() => _SaveDataState();
}

class _SaveDataState extends State<SaveData> {
  final UserSessions userSessions = UserSessions();
  final DatabaseHelper dbHelper = DatabaseHelper();
  final DekManager dekManager = DekManager();

  late List<Map<String, dynamic>> files;
  late bool filesIsInit;

  @override
  void initState() {
    super.initState();

    log("[SaveData] patientHash: ${widget.patientHash}");

    filesIsInit = false;

    getData();
  }

  Future<void> getData() async {
    List<Map<String, dynamic>> data = [];
    if (widget.patientHash == null) {
      data = await dbHelper.getFiles();
    } else {
      data = await dbHelper.getFilesByPatientHash(
        widget.patientHash,
      );
    }
    log("$data");

    setState(() {
      files = data;
      filesIsInit = true;
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
            SizedBox(
              height: screenWidth * 0.1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: screenWidth * 0.06,
                    height: screenWidth * 0.06,
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: const Color.fromARGB(255, 0, 31, 99),
                          foregroundColor: Colors.white, // 텍스트 색상
                          elevation: 5,
                        ),
                        child: Icon(
                          Icons.arrow_back_outlined,
                          size: screenWidth * 0.06,
                          color: Colors.white,
                        )),
                  ),
                  Spacer(),
                  BatteryStatus(size: screenWidth * 0.05),
                  SizedBox(width: screenWidth * 0.025),
                  WifiStatus(size: screenWidth * 0.05),
                  SizedBox(width: screenWidth * 0.025),
                  SizedBox(
                    height: screenWidth * 0.06,
                    child: Image.asset("assets/images/logo.png"),
                  )
                ],
              ),
            ),
            Row(
              children: [
                Expanded(child: SizedBox.shrink(),),
                SizedBox(
                  width: screenWidth * 0.05,
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
                SizedBox(
                  width: screenWidth * 0.05,
                ),
                Expanded(
                  child: StorageUsage(),
                ),
              ],
            ),
            Expanded(
              child: Container(
                child: Column(
                  children: [
                    getUserListheader(screenWidth),
                    Expanded(
                      child: filesIsInit
                          ? ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: files.length, // 항목의 총 개수
                              itemBuilder: (context, index) {
                                return getSaveFileListItem(files[index], index,
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
    );
  }

  Widget getUserListheader(screenWidth) {
    Color backgourndColor = const Color.fromARGB(255, 0, 31, 99);
    return Row(
      children: [
        Container(
          width: screenWidth * 0.3,
          height: screenWidth * 0.03,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
          decoration: BoxDecoration(
            color: backgourndColor,
          ),
          child: Text(
            "Name",
            style:
                TextStyle(fontSize: screenWidth * 0.015, color: Colors.white),
          ),
        ),
        Container(
          width: screenWidth * 0.15,
          height: screenWidth * 0.03,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
          decoration: BoxDecoration(
            color: backgourndColor,
          ),
          child: Text(
            "Creator",
            style:
                TextStyle(fontSize: screenWidth * 0.015, color: Colors.white),
          ),
        ),
        Container(
          width: screenWidth * 0.1,
          height: screenWidth * 0.03,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
          decoration: BoxDecoration(
            color: backgourndColor,
          ),
          child: Text(
            "File Type",
            style:
                TextStyle(fontSize: screenWidth * 0.015, color: Colors.white),
          ),
        ),
        Container(
          width: screenWidth * 0.15,
          height: screenWidth * 0.03,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
          decoration: BoxDecoration(
            color: backgourndColor,
          ),
          child: Text(
            "Create",
            style:
                TextStyle(fontSize: screenWidth * 0.015, color: Colors.white),
          ),
        ),
        Container(
          width: screenWidth * 0.15,
          height: screenWidth * 0.03,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
          decoration: BoxDecoration(
            color: backgourndColor,
          ),
          child: Text(
            "File Size",
            style:
                TextStyle(fontSize: screenWidth * 0.015, color: Colors.white),
          ),
        ),
        Container(
          width: screenWidth * 0.1,
          height: screenWidth * 0.03,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
          decoration: BoxDecoration(
            color: backgourndColor,
          ),
          child: Text(
            "Delete",
            style:
                TextStyle(fontSize: screenWidth * 0.015, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget getSaveFileListItem(
      Map<String, dynamic> saveFile, int index, screenWidth, screenHeight) {
    log("$saveFile");
    Color backgourndColor =
        index % 2 == 0 ? Color.fromARGB(255, 200, 200, 200) : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          log("click: $index");
          log("file:  ${files[index]}");
          if (files[index]["file_type"] == "IMAGE") {
            final imageFiles =
                files.where((f) => f["file_type"] == "IMAGE").toList();
            final imageIndex = imageFiles.indexWhere((f) => f == files[index]);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ImageViwer(
                  user: widget.user,
                  files: imageFiles,
                  index: imageIndex,
                ),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => VideoViewer(
                  user: widget.user,
                  files: files,
                  index: index,
                ),
              ),
            );
          }
        },
        splashColor: Colors.black26,
        highlightColor: Colors.black26,
        child: Ink(
          color: Colors.white,
          child: Row(
            children: [
              buildInkContainer(
                width: screenWidth * 0.3,
                height: screenWidth * 0.04,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
                color: backgourndColor,
                child: Text(
                  saveFile["name"] ?? saveFile["file_name"],
                  style: TextStyle(fontSize: screenWidth * 0.015),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              buildInkContainer(
                width: screenWidth * 0.15,
                height: screenWidth * 0.04,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
                color: backgourndColor,
                child: Text(
                  saveFile["user_name"],
                  style: TextStyle(fontSize: screenWidth * 0.015),
                ),
              ),
              buildInkContainer(
                width: screenWidth * 0.1,
                height: screenWidth * 0.04,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
                color: backgourndColor,
                child: Text(
                  saveFile["file_type"],
                  style: TextStyle(fontSize: screenWidth * 0.015),
                ),
              ),
              buildInkContainer(
                width: screenWidth * 0.15,
                height: screenWidth * 0.04,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
                color: backgourndColor,
                child: Text(
                  formatDateTimeSimple(saveFile["created_at"]),
                  style: TextStyle(fontSize: screenWidth * 0.015),
                ),
              ),
              buildInkContainer(
                width: screenWidth * 0.15,
                height: screenWidth * 0.04,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
                color: backgourndColor,
                child: Text(
                  "${((saveFile["file_size"] ?? 1) / 1024 / 1024).toStringAsFixed(3)} MB",
                  style: TextStyle(fontSize: screenWidth * 0.015),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              buildInkContainer(
                width: screenWidth * 0.1,
                height: screenWidth * 0.04,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
                color: backgourndColor,
                child: IconButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('삭제 확인'),
                        content: Text('정말 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false), // 취소
                            child: Text('아니오'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true), // 확인
                            child: Text('예'),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return; // 사용자가 '예'를 누르지 않은 경우 중단

                    log("delete: ${saveFile["id"]}");
                    if (!await userSessions.isSessionValid()) {
                      userSessions.logout(context);
                      return;
                    }

                    dbHelper.deleteFile(saveFile["id"]).then((_) {
                      log("$_");
                      getData();
                    });
                  },
                  icon: Icon(Icons.delete),
                ),
              ),
            ],
          ),
        ),
      ),
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
    return isoString.substring(0, 16).replaceFirst('T', ' ');
  }
}
