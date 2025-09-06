import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pentype_probe_viewer/database/dek_rsa_manager.dart';
import 'package:video_player/video_player.dart';

class VideoViewer extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> files;
  final int index;

  const VideoViewer({
    Key? key,
    required this.user,
    required this.files,
    required this.index,
  }) : super(key: key);

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  static const MethodChannel _cryptoChannel =
      MethodChannel('crypto_channel');
  final dekManager = DekManager();

  VideoPlayerController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _prepareAndPlay();
  }

  Future<void> _prepareAndPlay() async {
    try {
      final fileData = widget.files[widget.index];
      final fileName = fileData['file_name'] as String;
      final ivBase64 = fileData['file_iv'] as String;
      final encryptedDekBase64 = fileData['encrypted_dek'] as String;

      final dekBytes = await dekManager.getDekBytes(encryptedDekBase64);
      log(base64Encode(dekBytes));
      final ivBytes = base64Decode(ivBase64);
      log("ivBase64: $ivBase64");

      final dir = await getApplicationSupportDirectory();
      final encPath = '${dir.path}/MyApp/$fileName.mp4.enc';
      final decPath = '${dir.path}/MyApp/read_tmp.mp4';

      final decryptedFile = await decryptFileWithMethodChannel(
        inputPath: encPath,
        outputPath: decPath,
        dek: dekBytes,
        iv: ivBytes,
      );

      final controller = VideoPlayerController.file(decryptedFile);
      await controller.initialize();
      controller.setLooping(true);
      controller.play();

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e, stack) {
      debugPrint('❌ 영상 복호화 오류: $e');
      debugPrint('📛 Stacktrace:\n$stack');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<File> decryptFileWithMethodChannel({
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
      throw Exception('복호화 실패 (native)');
    }

    return File(outputPath);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.files[widget.index]['file_name'];

    return Scaffold(
      appBar: AppBar(title: Text('영상 보기 - $fileName')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_controller == null || !_controller!.value.isInitialized)
              ? const Center(child: Text('영상을 재생할 수 없습니다'))
              : Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                ),
      floatingActionButton: _controller != null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
              child: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
