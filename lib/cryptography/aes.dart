import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'dart:typed_data';
import 'package:ntruchat/constants/constants.dart';

String encryptAES(key, plaintext) {
  try {
    Uint8List keyBytes = Uint8List.fromList(key);
    final encrypter = Encrypter(AES(Key.fromUtf8(new String.fromCharCodes(keyBytes))));
    final encrypted = encrypter.encrypt(plaintext, iv: IV.fromBase64(GlobalConstants.IV));

    return encrypted.base64;
  } catch (e) {
    return "";
  }
}

String decryptAES(key, ciphertext) {
  try {
    Uint8List keyBytes = Uint8List.fromList(key);
    final encrypter = Encrypter(AES(Key.fromUtf8(new String.fromCharCodes(keyBytes))));
    final decrypted = encrypter.decrypt(Encrypted.fromBase64(ciphertext), iv: IV.fromBase64(GlobalConstants.IV));

    return decrypted;
  } catch (e) {
    return "";
  }
}