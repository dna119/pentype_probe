import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path/path.dart';
import 'package:pentype_probe_viewer/database/dek_rsa_manager.dart';
import 'package:sqflite/sqflite.dart';

import 'dart:developer' as dev;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  final dekManager = DekManager();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'user_management.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        salt TEXT NOT NULL,
        name TEXT NOT NULL,
        authority TEXT NOT NULL CHECK(authority IN ('ADMIN', 'USER')),  
        is_locked INTEGER DEFAULT 0,
        login_attempts INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_name TEXT NOT NULL,
        file_iv TEXT,
        file_size INTEGER,
        
        user_name TEXT NOT NULL,
      
        patient_id TEXT,
        patient_id_iv TEXT,
        
        patient_hash TEXT,
      
        file_type TEXT NOT NULL CHECK(file_type IN ('VIDEO', 'IMAGE')),
      
        encrypted_dek TEXT,
      
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    // Insert default admin user with salt-based hashed password
    String salt = generateSalt();
    String defaultPassword = hashPassword('admin', salt);

    await db.insert('users', {
      'user_id': 'admin',
      'password': defaultPassword,
      'salt': salt,
      'name': 'admin',
      'authority': 'ADMIN',
      'is_locked': 0,
      'login_attempts': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': null,
      'deleted_at': null,
    });
  }

  String generatePatientHash(String patientId, String secretKey) {
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmac.convert(utf8.encode(patientId));
    return digest.toString();
  }

  //User
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;

    // salt 생성
    final salt = generateSalt();
    final hashedPassword = hashPassword(user['password'], salt);

    user['salt'] = salt;
    user['password'] = hashedPassword;

    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //Files
  Future<int> insertFile(Map<String, dynamic> file) async {
    print("insertFile");
    final db = await database;

    return await db.insert('files', file);
  }

  Future<List<Map<String, dynamic>>> getFiles() async {
    final db = await database;
    List<Map<String, dynamic>> data = await db.query(
      'files',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );

    List<Map<String, dynamic>> decryptedList = await Future.wait(data.map((fileData) async {
      try {
        final dekBytes = await dekManager.getDekBytes(fileData['encrypted_dek']);
        final decryptedId = await _decryptTextWithDek(
          encryptedBase64: fileData['patient_id'],
          ivBase64: fileData['patient_id_iv'],
          dek: dekBytes,
        );

        return {
          ...fileData,
          'patient_id': decryptedId,
        };
      } catch (e) {
        dev.log("❌ 복호화 실패: $e");
        return fileData;
      }
    }).toList());

    return decryptedList;
  }

  Future<List<Map<String, dynamic>>> getFilesByPatientHash(String? patientHash) async {
    final db = await database;

    List<Map<String, dynamic>> data = await db.query(
      'files',
      where: 'patient_hash = ? AND deleted_at IS NULL',
      whereArgs: [patientHash],
      orderBy: 'created_at DESC',
    );

    List<Map<String, dynamic>> decryptedList = await Future.wait(data.map((fileData) async {
      try {
        final dekBytes = await dekManager.getDekBytes(fileData['encrypted_dek']);
        final decryptedId = await _decryptTextWithDek(
          encryptedBase64: fileData['patient_id'],
          ivBase64: fileData['patient_id_iv'],
          dek: dekBytes,
        );

        return {
          ...fileData,
          'patient_id': decryptedId,
        };
      } catch (e) {
        return fileData;
      }
    }).toList());

    return decryptedList;
  }

  Future<int> deleteFile(int id) async {
    final db = await database;
    return await db.delete(
      'files',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> unlockUser(String userId) async {
    final db = await database;
    await db.update(
      'users',
      {
        'is_locked': 0,
        'login_attempts': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, dynamic>>> getPatientList() async {
    final Database db = await database;

    final List<Map<String, dynamic>> rows = await db.query(
      'files',
      columns: [
        'patient_id',
        'patient_id_iv',
        'encrypted_dek',
        'updated_at',
        'file_size',
        'patient_hash',
      ],
    );

    final Map<String, List<DateTime>> updateMap = {};
    final Map<String, int> countMap = {};
    final Map<String, int> sizeMap = {};
    final Map<String, String> hashMap = {};

    for (final row in rows) {
      try {
        final encryptedDek = row['encrypted_dek'];
        final encryptedId = row['patient_id'];
        final encryptedIv = row['patient_id_iv'];

        if (encryptedDek == null || encryptedId == null || encryptedIv == null) {
          dev.log("Skipping row due to null values");
          continue; // 이 row 건너뜀
        }

        final dekBytes = await dekManager.getDekBytes(row['encrypted_dek']);

        final String decryptedId = await _decryptTextWithDek(
          encryptedBase64: row['patient_id'],
          ivBase64: row['patient_id_iv'],
          dek: dekBytes,
        );

        final updatedAt = row['updated_at'] != null
            ? DateTime.tryParse(row['updated_at'])
            : null;
        final fileSize = row['file_size'] ?? 0;
        final fileSizeInt = (fileSize is int) ? fileSize : (fileSize as num).toInt();

        updateMap.putIfAbsent(decryptedId, () => []);
        if (updatedAt != null) updateMap[decryptedId]!.add(updatedAt);

        countMap.update(decryptedId, (value) => value + 1, ifAbsent: () => 1);
        sizeMap.update(
          decryptedId,
              (value) => value + fileSizeInt,
          ifAbsent: () => fileSizeInt,
        );

        if (!hashMap.containsKey(decryptedId)) {
          final hash = row['patient_hash'];
          if (hash != null) {
            hashMap[decryptedId] = hash;
          }
        }

      } catch (e) {
        dev.log("Failed to process row: $e");
        return [];
      }
    }

    final result = updateMap.keys.map((patientId) {
      final updates = updateMap[patientId] ?? [];
      final lastUpdated = updates.isEmpty
          ? null
          : updates.reduce((a, b) => a.isAfter(b) ? a : b);

      return {
        'patientId': patientId,
        'count': countMap[patientId] ?? 0,
        'lastUpdated': lastUpdated?.toIso8601String(),
        'totalFileSize': sizeMap[patientId] ?? 0,
        'patientHash': hashMap[patientId],
      };
    }).toList();

    return result;
  }

  Future<String> _decryptTextWithDek({
    required String encryptedBase64,
    required String ivBase64,
    required Uint8List dek,
  }) async {
    final key = encrypt.Key(dek);
    final iv = encrypt.IV(base64.decode(ivBase64));
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

    final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);

    return encrypter.decrypt(encrypted, iv: iv);
  }
}

String generateSalt([int length = 16]) {
  final rand = Random.secure();
  final saltBytes = List<int>.generate(length, (_) => rand.nextInt(256));
  return base64Url.encode(saltBytes);
}

String hashPassword(String password, String salt) {
  final combined = utf8.encode(password + salt);
  final digest = sha256.convert(combined);
  return digest.toString();
}

String generateHashedFileName() {
  final random = Random();
  final salt = random.nextInt(100000).toString();
  final currentTime = DateTime.now().toIso8601String();
  final bytes = utf8.encode(salt + currentTime);
  final digest = sha256.convert(bytes);

  return digest.toString();
}
