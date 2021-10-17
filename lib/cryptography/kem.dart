import 'package:shared_preferences/shared_preferences.dart';
import './ntru.dart';
import './polynomial.dart';
import './helper.dart';

Future<List<int>> generateSecretKey(String selfPublicKeyString, String receiverPublicKeyString) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
  NTRU ntru = new NTRU();
  int N = ntru.N;
  
  List<int> selfPublicKey = polynomialToListOfInt(Polynomial.fromCommaSeparatedCoefficients(N, selfPublicKeyString), radix: 10);
  List<int> receiverPublicKey = polynomialToListOfInt(Polynomial.fromCommaSeparatedCoefficients(N, receiverPublicKeyString), radix: 10);
  ntru = NTRU.fromKeyPair(listOfIntToPolynomial(selfPublicKey, N).encodeCoefficientsToCommaSeparatedValue(), prefs.getString('privkey_f')!, prefs.getString('privkey_fp')!);

  Polynomial msg1 = listOfIntToPolynomial(receiverPublicKey, N);
  Polynomial r = generateRandomPolynomial(N);
  Polynomial encrypted = ntru.encrypt(msg1, r);
  List<int> final_key = [];

  encrypted = ntru.encrypt(msg1, r);
  return polynomialToListOfInt(encrypted, radix: 10);
}