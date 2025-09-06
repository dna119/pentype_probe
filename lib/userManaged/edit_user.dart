import 'package:flutter/material.dart';
import 'dart:math';

import '../database/database.dart';

Future<bool> showUserEditDialog(BuildContext context, Map<String, dynamic> user, int currentUserId) async {
  final TextEditingController nameController = TextEditingController(text: user['name']);
  bool isLocked = user['is_locked'] == 1;

  bool updated = false;
  final bool isSelf = user['id'] == currentUserId;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('사용자 정보 수정'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: '사용자명'),
                ),
                Row(
                  children: [
                    Text('잠금 상태:'),
                    Switch(
                      value: isLocked,
                      onChanged: isSelf ? null : (value) => setState(() => isLocked = value),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  final db = DatabaseHelper();
                  await db.updateUser(user['id'], {
                    'name': nameController.text,
                    'is_locked': isLocked ? 1 : 0,
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                  updated = true;
                  Navigator.pop(context);
                },
                child: Text('저장'),
              ),
              TextButton(
                onPressed: () async {
                  final db = DatabaseHelper();
                  final newPassword = _generateTempPassword();
                  final salt = generateSalt();
                  final hashed = hashPassword(newPassword, salt);

                  await db.updateUser(user['id'], {
                    'password': hashed,
                    'salt': salt,
                    'updated_at': null,
                  });

                  updated = true;

                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("임시 비밀번호"),
                      content: Text("새 비밀번호: $newPassword"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('확인'),
                        ),
                      ],
                    ),
                  );

                  Navigator.pop(context);
                },
                child: Text('비밀번호 초기화'),
              ),
              if (!isSelf)
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text("사용자 삭제"),
                        content: Text("정말로 이 사용자를 삭제하시겠습니까?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('삭제'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final db = DatabaseHelper();
                      await db.deleteUser(user['id']);
                      updated = true;
                      Navigator.pop(context);
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('삭제'),
                ),
            ],
          );
        },
      );
    },
  );

  return updated;
}


// 임시 비밀번호 생성 함수
String _generateTempPassword({int length = 8}) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rand = Random.secure();
  return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
}
