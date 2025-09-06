import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pentype_probe_viewer/information/license.dart';
import 'package:url_launcher/url_launcher.dart';

class SoftwareInformation extends StatelessWidget {
  final Uri homepageUri = Uri.parse('http://www.kmain.kr');
  final bool isLogin;

  SoftwareInformation({super.key, this.isLogin = true});

  Future<String> _fetchVersion() async {
    final info = await PackageInfo.fromPlatform();
    return "${info.version}";
  }

  Future<String> _loadReleaseNote() async {
    final changelog = await rootBundle.loadString('assets/release.md');
    return changelog;
  }

  Future<void> _launchHomepage() async {
    if (!await launchUrl(homepageUri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $homepageUri';
    }
  }

  void _checkLatestVersion(String currentVersion) {
    const latestVersion = "1.0.0"; // 예시용

    if (currentVersion == latestVersion) {
      Fluttertoast.showToast(msg: "최신 버전입니다.");
    } else {
      Fluttertoast.showToast(msg: "최신 버전은 $latestVersion입니다. 업데이트를 권장합니다.");
    }
  }

  void _openStorePage(BuildContext context) async {
    const url =
        'https://play.google.com/store/apps/details?id=com.example.app'; // 실제 앱 ID로 교체
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showDialog("스토어 페이지를 열 수 없습니다.", context);
    }
  }

  void _showDialog(String message, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("알림"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _fetchVersion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('버전 정보를 불러오는 데 실패했습니다')),
          );
        }

        final version = snapshot.data ?? '버전 정보 없음';
        return _buildSoftwareInfoUI(version);
      },
    );
  }

  Widget _buildSoftwareInfoUI(String version) {
    return FutureBuilder<String>(
      future: _loadReleaseNote(),
      builder: (context, snapshot) {
        final changelog = snapshot.data ?? '업데이트 내역을 불러오는 데 실패했습니다.';

        return Scaffold(
          appBar: AppBar(title: const Text('소프트웨어 정보')),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Image.asset("assets/images/logo.png", height: 100),
                          const SizedBox(height: 16),
                          const Text(
                            "K-Probe 1X-Navigator",
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "모델명: KM-FL-01",
                            style:
                                TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                          Text("버전 1.0"),
                          const SizedBox(height: 16),
                          if (isLogin)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () => _checkLatestVersion(version),
                                  child: const Text("최신 버전 확인"),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: () => _openStorePage(context),
                                  child: const Text("업데이트 하기"),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text("개발사",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("주식회사 케이마인"),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text("홈페이지",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _launchHomepage,
                      child: const Text(
                        'http://www.kmain.kr',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text("법적 고지",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            // TODO: 개인정보 처리방침 보기
                          },
                          child: const Text("개인정보 처리방침"),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: 이용약관 보기
                          },
                          child: const Text("이용약관"),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LicenseScreen()),
                        );
                      },
                      child: const Text("오픈소스 라이선스 보기"),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text("문의",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const SelectableText("support@kmain.com"),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text("업데이트 내역",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    MarkdownBody(data: changelog),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
