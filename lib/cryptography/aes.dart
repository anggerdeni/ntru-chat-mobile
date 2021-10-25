import 'package:encrypt/encrypt.dart';
import 'package:ntruchat/constants/constants.dart';

String encryptAES(key, plaintext) {
  try {
    final encrypter = Encrypter(AES(Key.fromBase64(key)));
    final encrypted = encrypter.encrypt(plaintext,
        iv: IV.fromBase64(GlobalConstants.IV));

    return encrypted.base64;
  } catch (e) {
    print("ERROR encrypt $e");
    return "";
  }
}

String decryptAES(key, ciphertext) {
  try {
    final encrypter = Encrypter(AES(Key.fromBase64(key)));
    final decrypted = encrypter.decrypt(
        Encrypted.from64(ciphertext),
        iv: IV.fromBase64(GlobalConstants.IV));

    return decrypted;
  } catch (e) {
    print("ERROR decrypt $e");
    return "";
  }
}
