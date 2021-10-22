import 'package:crypto/crypto.dart';
import 'dart:convert';

String sha256digest(message) {
  return sha1.convert(utf8.encode(message)).toString();
}