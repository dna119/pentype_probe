import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:path_provider/path_provider.dart';

class StorageUsage extends StatelessWidget {
  const StorageUsage({super.key});

  Future<Map<String, dynamic>> _getStorageData() async {
    double? total = await DiskSpacePlus.getTotalDiskSpace;
    double? free = await DiskSpacePlus.getFreeDiskSpace;
    double used = (total ?? 0) - (free ?? 0);

    int appBytes = await _getAppUsedStorage();
    double appMB = appBytes / (1024 * 1024);

    return {
      'total': total ?? 0,
      'free': free ?? 0,
      'used': used,
      'app': appMB,
    };
  }

  Future<int> _getAppUsedStorage() async {
    final directories = [
      await getApplicationDocumentsDirectory(),
      await getTemporaryDirectory(),
      await getApplicationSupportDirectory(),
    ];

    int total = 0;
    for (var dir in directories) {
      total += await _getDirectorySize(dir);
    }

    log("앱 내부 저장소 총 사용량 (바이트): $total");
    return total;
  }


  Future<int> _getDirectorySize(Directory dir) async {
    int total = 0;
    if (await dir.exists()) {
      final files = dir.listSync(recursive: true);
      for (var file in files) {
        if (file is File) {
          total += await file.length();
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getStorageData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          log("에러 발생: ${snapshot.error}");
          return Center(child: Text("에러 발생: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("저장소 정보를 불러올 수 없습니다."));
        }

        final data = snapshot.data!;
        final total = data['total'];
        final used = data['used'];
        final free = data['free'];
        final appMB = data['app'];
        final appGB = appMB / 1024;

        final usedPercent = (used / total).clamp(0.0, 1.0);
        final freePercent = (free / total).clamp(0.0, 1.0);
        final appPercent = (appGB / total).clamp(0.0, 1.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("저장소 사용률", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: (appPercent * 1000).toInt(),
                    child: Container(color: Colors.blueAccent),
                  ),
                  Expanded(
                    flex: ((usedPercent - appPercent) * 1000).toInt(),
                    child: Container(color: Colors.redAccent),
                  ),
                  Expanded(
                    flex: (freePercent * 1000).toInt(),
                    child: Container(color: Colors.grey[300]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text("총 용량: ${total.toStringAsFixed(2)} MB"),
            Text("사용 중: ${used.toStringAsFixed(2)} MB"),
            Text("남은 용량: ${free.toStringAsFixed(2)} MB"),
            Text("앱 내부 사용량: ${appMB.toStringAsFixed(2)} MB"),
          ],
        );
      },
    );
  }
}
