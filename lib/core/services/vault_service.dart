import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;

import '../models/entry.dart';

class VaultService {
  static const String encryptionKeyKey = 'vault_encryption_key';
  static const String pinHashKey = 'pin_hash';
  static const String vaultBoxName = 'vault';

  static final _secureStorage = const FlutterSecureStorage();
  static final _localAuth = LocalAuthentication();

  static Future<bool> hasSetup() async {
    return await _secureStorage.read(key: pinHashKey) != null;
  }

  static Future<Uint8List> _getOrGenerateEncryptionKey() async {
    String? stored = await _secureStorage.read(key: encryptionKeyKey);
    if (stored != null) {
      return base64Decode(stored);
    }

    final key = Hive.generateSecureKey(); // 32 bytes
    await _secureStorage.write(
      key: encryptionKeyKey,
      value: base64Encode(key),
    );
    return Uint8List.fromList(key);
  }

  static Future<Box<VaultEntry>> openVaultBox() async {
    final key = await _getOrGenerateEncryptionKey();
    return await Hive.openBox<VaultEntry>(
      vaultBoxName,
      encryptionCipher: HiveAesCipher(key),
    );
  }

// ────────────────────────────────────────────────
// Export مع تشفير إضافي بكلمة مرور
// ────────────────────────────────────────────────

static Future<File?> exportVault(String exportPassword) async {
  final box = await openVaultBox();
  final map = <String, dynamic>{};

  for (var key in box.keys) {
    final entry = box.get(key);
    if (entry != null) {
      map[key.toString()] = entry.toJson();
    }
  }

  final json = jsonEncode(map);

  // تشفير الـ JSON بكلمة المرور
  final encryptedJson = _encryptString(json, exportPassword);

  final dir = await getApplicationDocumentsDirectory();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final path = '${dir.path}/vaultnote_backup_$timestamp.vault';
  final file = File(path);
  await file.writeAsString(encryptedJson);

  return file;
}

// ────────────────────────────────────────────────
// Import مع فك التشفير بكلمة المرور
// ────────────────────────────────────────────────

static Future<bool> importVault(File file, String importPassword) async {
  try {
    final encryptedContent = await file.readAsString();

    // فك التشفير
    final jsonStr = _decryptString(encryptedContent, importPassword);

    final map = jsonDecode(jsonStr) as Map<String, dynamic>;

    final box = await openVaultBox();
    await box.clear();

    for (var entry in map.entries) {
      final vaultEntry = VaultEntry.fromJson(entry.value);
      await box.put(entry.key, vaultEntry);
    }
    return true;
  } catch (e) {
    print('Import failed: $e');
    return false;
  }
}

// ────────────────────────────────────────────────
// دوال مساعدة للتشفير / فك التشفير (AES-256-CBC)
// ────────────────────────────────────────────────

static String _encryptString(String plainText, String password) {
  final key = encrypt_lib.Key.fromUtf8(_padTo32Bytes(password));
  final iv = encrypt_lib.IV.fromSecureRandom(16);

  final encrypter = encrypt_lib.Encrypter(
    encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc),
  );

  final encrypted = encrypter.encrypt(plainText, iv: iv);
  final combined = iv.base64 + ':' + encrypted.base64;
  return combined;
}

static String _decryptString(String encryptedText, String password) {
  final parts = encryptedText.split(':');
  if (parts.length != 2) throw Exception('Invalid encrypted format');

  final iv = encrypt_lib.IV.fromBase64(parts[0]);
  final ciphertext = encrypt_lib.Encrypted.fromBase64(parts[1]);

  final key = encrypt_lib.Key.fromUtf8(_padTo32Bytes(password));

  final encrypter = encrypt_lib.Encrypter(
    encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc),
  );

  return encrypter.decrypt(ciphertext, iv: iv);
}

static String _padTo32Bytes(String input) {
  final bytes = utf8.encode(input);
  if (bytes.length >= 32) {
    return utf8.decode(bytes.sublist(0, 32));
  }
  final padding = List.filled(32 - bytes.length, 0);
  return utf8.decode(bytes + padding);
}


  // ────────────────────────────────────────────────
  // PIN logic
  // ────────────────────────────────────────────────

  static Future<void> setupPin(String pin) async {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes).bytes;
    await _secureStorage.write(
      key: pinHashKey,
      value: base64Encode(hash),
    );
  }

  static Future<bool> verifyPin(String pin) async {
    final storedBase64 = await _secureStorage.read(key: pinHashKey);
    if (storedBase64 == null) return false;

    final inputBytes = utf8.encode(pin);
    final inputHash = sha256.convert(inputBytes).bytes;
    return storedBase64 == base64Encode(inputHash);
  }

  // ────────────────────────────────────────────────
  // Biometric
  // ────────────────────────────────────────────────

  static Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock your VaultNote',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ────────────────────────────────────────────────
  // Export / Import (simple json version – can be improved)
  // ────────────────────────────────────────────────

  static Future<File?> exportVault() async {
    final box = await openVaultBox();
    final map = <String, dynamic>{};

    for (var key in box.keys) {
      final entry = box.get(key);
      if (entry != null) {
        map[key.toString()] = entry.toJson(); // تحتاج toJson في VaultEntry
      }
    }

    final json = jsonEncode(map);
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/vaultnote_backup_${DateTime.now().millisecondsSinceEpoch}.vault';
    final file = File(path);
    await file.writeAsString(json);

    return file;
  }

  static Future<bool> importVault(File file) async {
    try {
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;

      final box = await openVaultBox();
      await box.clear();

      for (var entry in map.entries) {
        final vaultEntry = VaultEntry.fromJson(entry.value);
        await box.put(entry.key, vaultEntry);
      }
      return true;
    } catch (e) {
      print('Import error: $e');
      return false;
    }
  }
}

// Extension لتحويل VaultEntry <-> JSON (ضيفها في entry.dart أو هنا)
extension VaultEntryJson on VaultEntry {
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'usernameOrEmail': usernameOrEmail,
        'password': password,
        'note': note,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static VaultEntry fromJson(Map<String, dynamic> json) {
    return VaultEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      usernameOrEmail: json['usernameOrEmail'] as String?,
      password: json['password'] as String?,
      note: json['note'] as String?,
      category: json['category'] as String? ?? 'Other',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}