import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;

class DekManager {
  static const _channel = MethodChannel('kek_channel');

  Future<String> generateEncryptedDek() async {
    final dekBytes = Uint8List.fromList(List<int>.generate(32, (_) => Random.secure().nextInt(256)));
    final dekBase64 = base64.encode(dekBytes);
    dev.log("🔐 [Flutter] DEK 원문 (Base64): $dekBase64");

    try {
      final encryptedDekBase64 = await _channel.invokeMethod<String>('encryptDek', {"dek": dekBytes});

      if (encryptedDekBase64 == null) {
        throw Exception("DEK 암호화 실패: 암호문이 null입니다.");
      }

      dev.log("✅ [Flutter] 암호화된 DEK (Base64): $encryptedDekBase64");

      return encryptedDekBase64;
    } on PlatformException catch (e) {
      dev.log('Error encrypting DEK: ${e.code}, ${e.message}, ${e.details}');
      if (e.code == "RSA_ERROR") {
        throw Exception("RSA 암호화 오류: ${e.message}");
      }
      rethrow;
    } catch (e) {
      dev.log('Unexpected error in generateEncryptedDek: $e');
      rethrow;
    }
  }

  Future<String> decryptDek(String encryptedDekBase64) async {
    try {
      final result = await _channel.invokeMethod<String>('decryptDek', {'encryptedDek': encryptedDekBase64,});

      if (result == null) {
        throw Exception("DEK 복호화 실패: 결과가 null입니다.");
      }
      return result;
    } on PlatformException catch (e) {
      dev.log('Error decrypting DEK: ${e.code}, ${e.message}, ${e.details}');
      if (e.code == "RSA_ERROR") {
        throw Exception("RSA 복호화 오류: ${e.message}");
      }
      rethrow;
    } catch (e) {
      dev.log('Unexpected error in decryptDek: $e');
      rethrow;
    }
  }

  Future<Uint8List> getDekBytes(String encryptedDekBase64) async {
    final dekBase64 = await decryptDek(encryptedDekBase64);
    return base64.decode(dekBase64);
  }
}