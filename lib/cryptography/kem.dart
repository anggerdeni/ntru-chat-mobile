import './ntru.dart';
import './polynomial.dart';
import './helper.dart';
import './hash.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

List<String> generateSecretKey(
    String selfPublicKeyString,
    String privF,
    String privFp,
    String receiverPublicKeyString) {
  NTRU ntru = new NTRU();
  int N = ntru.N;

  ntru = NTRU.fromKeyPair(
      Polynomial.fromCommaSeparatedCoefficients(
              N, selfPublicKeyString)
          .encodeCoefficientsToCommaSeparatedValue(),
      privF,
      privFp);

  Polynomial r = generateRandomPolynomial(N);
  List<int> key = generateRandomInts(32);
  Polynomial msg = listOfIntToPolynomial(key, N);
  Polynomial receiverPublicKey =
      Polynomial.fromCommaSeparatedCoefficients(
          N, receiverPublicKeyString);
  Polynomial encrypted = r
      .multPolyMod2048(receiverPublicKey)
      .addPolyMod2048(msg);

  String keySession = base64.encode(key);
  Polynomial encryptedHash = r
      .multPolyMod2048(receiverPublicKey)
      .addPolyMod2048(listOfIntToPolynomial(
          sha256bytes(keySession), N));
  return [
    keySession,
    encrypted.encodeCoefficientsToCommaSeparatedValue(),
    encryptedHash.encodeCoefficientsToCommaSeparatedValue()
  ];
}

String decryptSecretKey(
    String selfPublicKeyString,
    String privF,
    String privFp,
    String receiverPublicKeyString,
    String encryptedKey,
    String hash) {
  NTRU ntru = new NTRU();
  int N = ntru.N;

  ntru = NTRU.fromKeyPair(
      Polynomial.fromCommaSeparatedCoefficients(
              N, selfPublicKeyString)
          .encodeCoefficientsToCommaSeparatedValue(),
      privF,
      privFp);

  Polynomial encryptedKeyPoly =
      Polynomial.fromCommaSeparatedCoefficients(
          N, encryptedKey);
  Polynomial key = ntru.decrypt(encryptedKeyPoly);
  String keySession = base64
      .encode(polynomialToListOfInt(key, numChunks: 32));

  Polynomial polyHash =
      Polynomial.fromCommaSeparatedCoefficients(N, hash);
  List<int> hashResult = polynomialToListOfInt(
      ntru.decrypt(polyHash),
      numChunks: 32);
  List<int> hashCheck = sha256bytes(keySession);
  if (listEquals(hashCheck, hashResult)) return keySession;
  return "";
}
