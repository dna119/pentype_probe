import 'dart:developer';

import 'package:flutter/material.dart';
import 'database.dart';
import 'dart:core';

class PasswordChangeDialog extends StatefulWidget {
  final Map<String, dynamic> user;

  const PasswordChangeDialog({super.key, required this.user});

  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();

  static Future<bool> show(BuildContext context, Map<String, dynamic> user) {
    return showDialog(
      context: context,
      builder: (context) => PasswordChangeDialog(user: user),
    ).then((value) => value ?? false);
  }
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final dbHelper = DatabaseHelper();

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'\d'));
    final hasSpecial = password.contains(RegExp('[!@#\$&*~%^()\-_=+{}\[\]:;\"\'<>,.?\/\\|]'));
    final isLongEnough = password.length >= 8;

    final conditionsMet = [
    hasUpper,
    hasLower,
    hasDigit,
    hasSpecial,
        ].where((c) => c).length;

    return isLongEnough && conditionsMet >= 3;
  }

  void _onConfirm() async {
    String newPassword = newPasswordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    if (!_validatePassword(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '비밀번호는 최소 8자 이상이어야 하며,\n대소문자, 숫자, 특수문자 중 3가지 이상을 포함해야 합니다.',
          ),
        ),
      );
      return;
    }

    log("비밀번호 평문: $newPassword");
    final salt = generateSalt();
    log("Salt 값: $salt");
    final hashedPassword = hashPassword(newPassword, salt);
    log("암호화된 비밀번호: $hashedPassword");

    final Map<String, dynamic> updateUser = {
      'password': hashedPassword,
      'salt': salt,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await dbHelper.updateUser(widget.user["id"], updateUser);

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('비밀번호 변경'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '새 비밀번호',
                helperText: '• 최소 8자 이상\n• 대소문자, 숫자, 특수문자 중 3가지 이상 조합',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '비밀번호 확인',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('취소'),
        ),
        TextButton(
          onPressed: _onConfirm,
          child: Text('확인'),
        ),
      ],
    );
  }
}
