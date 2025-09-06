import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';

class LicenseScreen extends StatefulWidget {
  @override
  _LicenseScreenState createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  String _licenseText = '';

  @override
  void initState() {
    super.initState();
    _loadLicense();
  }

  Future<void> _loadLicense() async {
    final text = await rootBundle.loadString('assets/open_source_license.md');
    setState(() {
      _licenseText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: Text('오픈소스 라이선스')),
      body: _licenseText.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: Container(
                width: screenWidth * 0.5,
                child: MarkdownBody(
                  data: _licenseText,
                ),
              )),
            ),
    );
  }
}
