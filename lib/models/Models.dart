import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

// User
class User {
  final String? id;
  final String? name;
  final String? email;
  final String? pubkey;

  User(
      {this.id,
      @required this.name,
      @required this.email,
      @required this.pubkey});
}

// User Data
class UserData {
  final String id;
  final String email;
  final String name;
  final String pubkey;

  UserData(this.id, this.email, this.name, this.pubkey);
}

// Dynamic Data for users
class ChatUsers {
  String? name;
  String? messageText;
  String? time;

  ChatUsers({
    @required this.name,
    @required this.messageText,
    @required this.time,
  });
}

// Chat Models
class ChatUser {
  String? receiverEmail;
  String? senderEmail;
  String? roomID;

  ChatUser(
      {@required this.receiverEmail,
      @required this.senderEmail,
      @required this.roomID});
}

// Message Model
class Message {
  String? id;
  String? roomID;
  String? txtMsg;
  String? receiverEmail;
  String? senderEmail;
  String? time;
  bool? sender;

  Message(
      {this.id,
      this.roomID,
      this.txtMsg,
      this.receiverEmail,
      this.senderEmail,
      this.time,
      this.sender});
}

// Chat History
@HiveType(typeId: 0)
class ChatHistory extends HiveObject {
  @HiveField(0)
  late List<int> sessionKey;

  @HiveField(1)
  List<dynamic>? messages;
}
