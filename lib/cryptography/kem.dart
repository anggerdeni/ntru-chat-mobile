import './ntru.dart';
import './polynomial.dart';
import './helper.dart';
import 'dart:convert';

List<String> generateSecretKey(String selfPublicKeyString, String privF, String privFp, String receiverPublicKeyString) {
  NTRU ntru = new NTRU();
  int N = ntru.N;
  
  ntru = NTRU.fromKeyPair(Polynomial.fromCommaSeparatedCoefficients(N, selfPublicKeyString).encodeCoefficientsToCommaSeparatedValue(), privF, privFp);

  Polynomial r = generateRandomPolynomial(N);
  List<int> key = generateRandomInts(32);
  Polynomial msg = listOfIntToPolynomial(key, N);
  Polynomial receiverPublicKey = Polynomial.fromCommaSeparatedCoefficients(N, receiverPublicKeyString);
  Polynomial encrypted = r
      .multPolyMod2048(receiverPublicKey)
      .addPolyMod2048(msg);
  return [base64.encode(key), encrypted.encodeCoefficientsToCommaSeparatedValue()];
}

String decryptSecretKey(String selfPublicKeyString, String privF, String privFp, String receiverPublicKeyString, String encryptedKey) {
  NTRU ntru = new NTRU();
  int N = ntru.N;

  ntru = NTRU.fromKeyPair(Polynomial.fromCommaSeparatedCoefficients(N, selfPublicKeyString).encodeCoefficientsToCommaSeparatedValue(), privF, privFp);

  Polynomial encryptedKeyPoly = Polynomial.fromCommaSeparatedCoefficients(N, encryptedKey);
  Polynomial key = ntru.decrypt(encryptedKeyPoly);
  return base64.encode(polynomialToListOfInt(key, numChunks: 32));
}