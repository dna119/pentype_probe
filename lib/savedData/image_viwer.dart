import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pentype_probe_viewer/database/dek_rsa_manager.dart';

class ImageViwer extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> files;
  final int index;

  const ImageViwer(
      {super.key,
      required this.user,
      required this.files,
      required this.index});

  @override
  State<ImageViwer> createState() => _ImageViwerState();
}

class _ImageViwerState extends State<ImageViwer> {
  static const MethodChannel _cryptoChannel = MethodChannel('crypto_channel');

  late int _index;
  late List<Map<String, dynamic>> _files;
  Uint8List? _imageBytes;

  final dekManager = DekManager();

  Future<void> loadImageFile() async {
    final fileData = _files[_index];
    final fileName = fileData["file_name"];
    final ivBase64 = fileData["file_iv"];
    final dekBase64 = fileData["encrypted_dek"];

    final inputPath = "/data/user/0/com.kmain.pentype_probe_viewer/files/MyApp/$fileName.png.enc";

    final encryptedFile = File(inputPath);
    if (!await encryptedFile.exists()) {
      print("파일 없음: $inputPath");
      setState(() => _imageBytes = null);
      return;
    }

    try {
      final dek = await dekManager.getDekBytes(dekBase64);
      final iv = base64Decode(ivBase64);

      final tempDir = await getTemporaryDirectory();
      final outputPath = "${tempDir.path}/$fileName.png";

      final bytes = await decryptImageFileWithMethodChannel(
        inputPath: inputPath,
        outputPath: outputPath,
        dek: dek,
        iv: iv,
      );

      setState(() => _imageBytes = bytes);
    } catch (e) {
      print("복호화 실패: $e");
      setState(() => _imageBytes = null);
    }
  }

  Future<Uint8List> decryptImageFileWithMethodChannel({
    required String inputPath,
    required String outputPath,
    required Uint8List dek,
    required Uint8List iv,
  }) async {
    final success = await _cryptoChannel.invokeMethod('decryptFile', {
      'input': inputPath,
      'output': outputPath,
      'dek': dek,
      'iv': iv,
    });

    if (success != true) {
      throw Exception("복호화 실패 (native)");
    }

    return await File(outputPath).readAsBytes();
  }

  @override
  void initState() {
    super.initState();
    _index = widget.index;
    _files = widget.files;
    loadImageFile();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            color: Colors.black,
            child: _imageBytes == null
                ? const CircularProgressIndicator()
                : InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.memory(_imageBytes!),
                  ),
          ),
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Visibility(
                  visible: _index > 0,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _index -= 1;
                        _imageBytes = null;
                      });
                      loadImageFile();
                    },
                    icon:
                        Icon(Icons.navigate_before, size: screenHeight * 0.15),
                  ),
                ),
                Visibility(
                  visible: _index < _files.length - 1,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _index += 1;
                        _imageBytes = null;
                      });
                      loadImageFile();
                    },
                    icon: Icon(Icons.navigate_next, size: screenHeight * 0.15),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
