import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pentype_probe_viewer/battery_status/battery_status.dart';
import 'package:pentype_probe_viewer/database/database.dart';
import 'package:pentype_probe_viewer/database/dek_rsa_manager.dart';
import 'package:pentype_probe_viewer/database/hmac_service.dart';
import 'package:pentype_probe_viewer/wifi_connect/wifi_connect_status.dart';

class Viewer extends StatefulWidget {
  final Map<String, dynamic> user;
  final String patientID;

  const Viewer({
    super.key,
    required this.user,
    required this.patientID,
  });

  @override
  State<Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<Viewer> {
  static const MethodChannel _platform = MethodChannel('ffmpeg_channel');
  static const MethodChannel _cryptoChannel = MethodChannel('crypto_channel');

  final dbHelper = DatabaseHelper();

  late int _idx;

  late bool _isCaptureProcess;
  late bool _isRecordProcess;

  final dekManager = DekManager();

  bool _isRecord = false;
  late String _recordFileName;

  bool _showRecordingIcon = true;
  Timer? _recordBlinkTimer;

  @override
  void initState() {
    super.initState();

    _idx = 0;
    _isCaptureProcess = false;
    _isRecordProcess = false;
    dev.log("patientID is Empty: ${widget.patientID.isEmpty}");

    _prepareConnectionAndStreaming(); // ✅ 연결 및 스트리밍 통합 실행
  }

  Future<void> _prepareConnectionAndStreaming() async {
    try {
      // 1. 장치에 연결 시도
      final result = await const MethodChannel('battery_channel')
          .invokeMethod<int>('reconnectToCam');

      if (result != 0) {
        dev.log("카메라 연결 실패: $result");
        // 연결 실패 시 처리 로직 (예: 사용자에게 알림)
        return;
      }

      dev.log("카메라 연결 성공");

      // 2. 스트리밍 시작
      await _startStreaming();
    } catch (e) {
      dev.log("오류 발생: $e");
    }
  }

  Future<void> _startStreaming() async {
    try {
      // RTSP 스트리밍
      await _platform.invokeMethod('stopStreaming');
      await _platform.invokeMethod('startStreaming', {
        "user_id": widget.user["name"],
        "patient_id": widget.patientID,
      });
    } on PlatformException catch (e) {
      dev.log("Error starting streaming: ${e.message}");
    }
  }

  Future<void> _capturePicture() async {
    dev.log("_capturePicture");
    setState(() {
      _isCaptureProcess = true;
    });
    try {
      final String dateTime = DateTime.now().toIso8601String();

      final encryptedDekBase64 = await dekManager.generateEncryptedDek();
      final dekBytes = await dekManager.getDekBytes(encryptedDekBase64);

      final Map<String, String> idEncrypted =
          await encryptTextWithDekWithIv(widget.patientID, dekBytes);

      final String fileName =
          "${widget.patientID}_${widget.user["name"]}_${dateTime.substring(0, 16).replaceFirst('T', ' ')}_$_idx";

      final iv = Uint8List.fromList(
          List.generate(12, (_) => Random.secure().nextInt(256)));

      final int fileSize =
          await _platform.invokeMethod('captureEncryptedRequest', {
        'file_name': fileName,
        'dek': base64Encode(dekBytes),
        'iv': base64Encode(iv),
      });

      final Map<String, dynamic> data = {
        'file_name': fileName,
        'file_iv': base64Encode(iv),
        'file_type': "IMAGE",
        'file_size': fileSize,
        'user_name': await widget.user["name"],
        'patient_id': idEncrypted['ciphertext'],
        'patient_id_iv': idEncrypted['iv'],
        'patient_hash': widget.patientID.isEmpty
            ? null
            : await HmacService.generatePatientHash(widget.patientID),
        'encrypted_dek': encryptedDekBase64,
        'created_at': dateTime,
        'updated_at': dateTime,
        'deleted_at': null,
      };

      dev.log("data : $data");

      // 4. DB 저장
      int state = await dbHelper.insertFile(data);

      dev.log("DB 저장 상태: $state");

      _idx++;
    } on PlatformException catch (e) {
      dev.log("Error trying capture: $e");
    }
    setState(() {
      _isCaptureProcess = false;
    });
  }

  Future<void> _startRecord() async {
    dev.log("Record");

    final dir = await getApplicationSupportDirectory();
    final tmpPath = '${dir.path}/MyApp/tmp.mp4';
    final tmpFile = File(tmpPath);

    final String dateTime = DateTime.now().toIso8601String();
    _recordFileName =
        "${widget.patientID}_${widget.user["name"]}_${dateTime.substring(0, 16).replaceFirst('T', ' ')}_$_idx";

    if (await tmpFile.exists()) {
      dev.log("🧹 기존 tmp.mp4 삭제");
      await tmpFile.delete();
    }

    try {
      await _platform.invokeMethod('recordStart', {
        'file_name': _recordFileName,
      });

      _recordBlinkTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
        setState(() {
          _showRecordingIcon = !_showRecordingIcon;
        });
      });

      _isRecord = true; // ✅ 성공 시에만 true로 설정
    } on PlatformException catch (e) {
      dev.log("Error trying capture: $e");

      Fluttertoast.showToast(
        msg: e.code == 'EGL_NOT_READY'
            ? "화면이 아직 준비되지 않았습니다. 잠시 후 다시 시도해주세요."
            : "녹화 시작 중 오류 발생: ${e.message}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      _isRecord = false;
    } catch (e, stack) {
      dev.log("Unexpected error: $e\n$stack");
      Fluttertoast.showToast(
        msg: "예상치 못한 오류가 발생했습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      _isRecord = false;
    }
  }

  Future<void> _stopRecord() async {
    _isRecordProcess = true;
    dev.log("_stopRecord");

    if (!_isRecord) {
      dev.log("⚠️ 녹화 중이 아니어서 recordStop을 건너뜁니다.");
      return;
    }

    final patientID = widget.patientID;
    final userName = widget.user["name"];
    final dateTime = DateTime.now().toIso8601String();
    final fileName = _recordFileName;
    final dir = await getApplicationSupportDirectory();

    dev.log("[_stopRecord] dir : ${dir.path}");

    try {
      await _platform.invokeMethod('recordStop');
      await _waitForFileStable('${dir.path}/MyApp/$fileName.mp4');

      final encryptedDekBase64 = await dekManager.generateEncryptedDek();
      final dekBytes = await dekManager.getDekBytes(encryptedDekBase64);
      final idEncrypted = await encryptTextWithDekWithIv(patientID, dekBytes);

      dev.log("[Viewer] encrypting with isolate at: ${dir.path}");

      final result = await encryptFileWithMethodChannel(
        dek: dekBytes,
        fileName: fileName,
        dirPath: dir.path,
      );
      dev.log("[Viewer] Encryption result: $result");

      final data = {
        'file_name': fileName,
        'file_iv': result["iv"],
        'file_type': "VIDEO",
        'file_size': result["size"],
        'user_name': userName,
        'patient_id': idEncrypted['ciphertext'],
        'patient_id_iv': idEncrypted['iv'],
        'patient_hash': patientID.isEmpty
            ? null
            : await HmacService.generatePatientHash(patientID),
        'encrypted_dek': encryptedDekBase64,
        'created_at': dateTime,
        'updated_at': dateTime,
        'deleted_at': null,
      };

      await dbHelper.insertFile(data);
      dev.log("✅ DB 저장 완료: $fileName");

      _idx++;
    } catch (e, stack) {
      dev.log("❌ 암호화 중 오류 발생: $e\n$stack");
    } finally {
      _isRecord = false; // ✅ 항상 false로 리셋
      _recordBlinkTimer?.cancel();
      _recordBlinkTimer = null;
      setState(() {
        _showRecordingIcon = true;
      });
    }
  }

  Future<void> _waitForFileStable(String path) async {
    const checkInterval = Duration(milliseconds: 300);
    const timeout = Duration(seconds: 5);

    final file = File(path);

    dev.log("[_waitForFileStable] path : $path");
    int lastSize = -1;
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      if (!await file.exists()) {
        // 파일이 아직 생성되지 않았으면 기다림
        await Future.delayed(checkInterval);
        continue;
      }

      final currentSize = await file.length();
      if (currentSize == lastSize && currentSize > 0) break;

      lastSize = currentSize;
      await Future.delayed(checkInterval);
    }

    if (!await file.exists()) {
      throw Exception("파일이 생성되지 않았습니다: $path");
    }
  }

  Future<Map<String, String>> encryptTextWithDekWithIv(
      String plainText, Uint8List dek) async {
    final iv = encrypt.IV(Uint8List.fromList(
        List.generate(12, (_) => Random.secure().nextInt(256))));
    final key = encrypt.Key(dek);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return {
      'ciphertext': encrypted.base64,
      'iv': base64Encode(iv.bytes),
    };
  }

  Future<Map<String, dynamic>> encryptFileWithMethodChannel({
    required Uint8List dek,
    required String fileName,
    required String dirPath,
  }) async {
    final iv = Uint8List.fromList(
        List.generate(12, (_) => Random.secure().nextInt(256)));

    final inputPath = '$dirPath/MyApp/$fileName.mp4';
    final outputPath = '$dirPath/MyApp/$fileName.mp4.enc';

    final result = await _cryptoChannel.invokeMethod('encryptFile', {
      'input': inputPath,
      'output': outputPath,
      'dek': dek,
      'iv': iv,
    });

    return {
      'iv': base64Encode(iv),
      'size': File(outputPath).lengthSync(),
    };
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(0.0),
            alignment: Alignment.center,
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: 16 / 9, // 16:9 비율 유지
              child: AndroidView(
                viewType: 'gl_surface_view',
                layoutDirection: TextDirection.ltr,
              ),
            ),
          ),
          _getControllerLayout(screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _getControllerLayout(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.025),
      alignment: Alignment.topRight,
      child: SizedBox(
        height: screenWidth * 0.075,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: screenHeight * 0.1,
              height: screenHeight * 0.1,
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
                    size: screenHeight * 0.075,
                    color: Colors.white,
                  )),
            ),
            Row(children: [
              BatteryStatus(
                size: screenWidth * 0.05,
                color: Colors.white,
              ),
              SizedBox(width: screenWidth * 0.025),
              WifiStatus(size: screenWidth * 0.05, color: Colors.white),
              SizedBox(width: screenWidth * 0.025),
              SizedBox(width: screenWidth * 0.05),
              Container(
                width: screenWidth * 0.075,
                // 컨테이너 너비
                height: screenWidth * 0.075,
                // 컨테이너 높이
                child: _isCaptureProcess
                    ? CircularProgressIndicator()
                    : IconButton(
                        onPressed: () {
                          _capturePicture();
                        },
                        iconSize: screenWidth * 0.075,
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.fit_screen_outlined, // 아이콘
                          color: Colors.red, // 아이콘 색상
                        ),
                      ),
              ),
              SizedBox(width: screenWidth * 0.05),
              Container(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 3),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      if (_isRecord) {
                        _stopRecord();
                      } else {
                        _startRecord();
                      }
                    });
                  },
                  iconSize: screenWidth * 0.04,
                  padding: EdgeInsets.zero,
                  icon: _isRecord
                      ? (_showRecordingIcon
                          ? Icon(_isRecordProcess ? Icons.save : Icons.circle,
                              color: Colors.red)
                          : Icon(_isRecordProcess ? Icons.save : Icons.circle,
                              color: Colors.transparent))
                      : const Icon(Icons.video_call_sharp, color: Colors.red),
                ),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
