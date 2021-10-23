import 'package:cryptography/dart.dart';
import 'dart:convert';

List<int> sha256bytes(message) {
  const hasher = DartSha256();
  final hash = hasher.hashSync(utf8.encode(message));
  return hash.bytes;
}