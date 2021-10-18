import 'package:shared_preferences/shared_preferences.dart';
import './ntru.dart';
import './polynomial.dart';
import './helper.dart';

List<int> generateSecretKey(String selfPublicKeyString, String privF, String privFp, String receiverPublicKeyString) {
  
  NTRU ntru = new NTRU();
  int N = ntru.N;
  
  List<int> selfPublicKey = polynomialToListOfInt(Polynomial.fromCommaSeparatedCoefficients(N, selfPublicKeyString), radix: 10);
  List<int> receiverPublicKey = polynomialToListOfInt(Polynomial.fromCommaSeparatedCoefficients(N, receiverPublicKeyString), radix: 10);
  ntru = NTRU.fromKeyPair(listOfIntToPolynomial(selfPublicKey, N).encodeCoefficientsToCommaSeparatedValue(), privF, privFp);

  Polynomial msg1 = listOfIntToPolynomial(receiverPublicKey, N);
  Polynomial r = generateRandomPolynomial(N);
  Polynomial encrypted = ntru.encrypt(msg1, r);

  encrypted = ntru.encrypt(msg1, r);
  return polynomialToListOfInt(encrypted, radix: 10);
}