import 'package:flutter/services.dart';

class HmacService {
  static const platform = MethodChannel('hmac');

  static Future<String> generatePatientHash(String patientId) async {
    final result = await platform.invokeMethod<String>(
      'generateHmac',
      {"patientId": patientId},
    );
    return result!;
  }
}