import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ntruchat/main.dart';
import 'package:ntruchat/store/actions/types.dart';
import 'package:ntruchat/store/reducer.dart';
import 'package:ntruchat/cryptography/kem.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:ntruchat/cryptography/aes.dart';
import 'package:ntruchat/cryptography/hash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';

Future<void> onUniqueChat({
  Store<ChatState>? store,
  Socket? socket,
  senderEmail,
  receiverEmail,
  receiverPubkey,
  selfPubkey,
}) async {
  
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Remove uniqueRooms
  // prefs.remove("_uniqueRooms");

  dynamic uniqueRoomsGetter = prefs.get("_uniqueRooms");
  dynamic uniqueRooms =
      (uniqueRoomsGetter == null) ? [] : json.decode(uniqueRoomsGetter);

  socket!.emit('startUniqueChat',
      {'senderEmail': senderEmail, 'receiverEmail': receiverEmail});

  socket.on('openChat', (user) {
    Map<String, String> mobileRoom = new Map();
    mobileRoom['receiverEmail'] = user['receiverEmail'];
    mobileRoom['senderEmail'] = user['senderEmail'];
    mobileRoom['roomID'] = user['roomID'];

    if (uniqueRooms.length > 0) {
      // Remove uniqueRooms from localStorage
      // prefs.remove("_uniqueRoom");

      // Check if our unique chats does contain a chat with
      //this current roomID from Database else add it to uniqueRooms
      dynamic list =
          uniqueRooms.where((item) => item['roomID'] == user['roomID']);

      // A little Delay
      Future.delayed(Duration(microseconds: 2));
      if (list.length == 0) {
        uniqueRooms.add(mobileRoom);
        prefs.setString("_uniqueRooms", json.encode(uniqueRooms));
      }

      socket.emit('joinTwoUsers', {'roomID': user['roomID']});
      store!.dispatch(UpdateRoomAction(user['roomID']));
    } else {
      uniqueRooms.add(mobileRoom);
      prefs.setString("_uniqueRooms", json.encode(uniqueRooms));
      store!.dispatch(UpdateRoomAction(user['roomID']));

      // Start New Chat
      socket.emit('joinTwoUsers', {'roomID': user['roomID']});
    }
  });
}

Future<void>? onSend({
  Store<ChatState>? store,
  Socket? socket,
  String? txtMsg,
  String? senderEmail,
  String? receiverEmail,
  receiverPubkey,
  selfPubkey,
}) async {
  if (txtMsg == "") {
  } else {
    const _boxName = 'inbox';
    dynamic formatedTime = DateTime.now().toUtc().microsecondsSinceEpoch;

    var box = Hive.box(_boxName);
    Map<String, dynamic> chatHistory = new Map();
    var hiveChatHistory = box.get(receiverEmail);

    print("$senderEmail sent encrypted message to $receiverEmail: $txtMsg");
    Map<String, dynamic> composeMsg = new Map();
    composeMsg['_id'] = Uuid().v4();
    composeMsg['roomID'] = store!.state.activeRoom;
    composeMsg['txtMsg'] = encryptAES(hiveChatHistory['sessionKey'], txtMsg);
    composeMsg['hash'] = sha256digest(txtMsg);
    composeMsg['receiverEmail'] = receiverEmail;
    composeMsg['senderEmail'] = senderEmail;
    composeMsg['time'] = formatedTime;
    composeMsg['sender'] = true;

    if(composeMsg['txtMsg'] != "") {
      chatHistory['sessionKey'] = hiveChatHistory['sessionKey'];
      chatHistory['messages'] = hiveChatHistory['messages'];
      chatHistory['messages'].add(composeMsg);
      box.put(receiverEmail, chatHistory);
      socket!.emit('sendTouser', composeMsg);
      composeMsg['txtMsg'] = txtMsg;
      store.dispatch(new UpdateDispatchMsg(composeMsg));
    }

  }
}

Future<void> loadUniqueChats(
    {Store? store,
    Socket? socket,
    String? currentUserEmail,
    String? otherUser}) async {
  Map<String, dynamic> chatDetails = new Map();
  chatDetails["senderEmail"] = currentUserEmail;
  chatDetails["receiverEmail"] = otherUser;

  socket!.emit('load_user_chats', chatDetails);
}

Future<void>? groupUniqueChats({
  Store? store,
  Socket? socket,
  receiverPubkey,
  selfPubkey,
  senderEmail
}) {
  const _boxName = 'inbox';
  socket!.on("loadUniqueChat", (chats) async {
    if (chats.isEmpty) {
      return;
    } else {
      var box = Hive.box(_boxName);
      var hiveChatHistory = box.get(chats["senderEmail"]);
      Map<String, dynamic> chat = new Map();
      chat["id"] = chats["_id"];
      chat["roomID"] = chats["roomID"];
      chat["senderEmail"] = chats["senderEmail"];
      chat["receiverEmail"] = chats["receiverEmail"];
      chat["time"] = chats["time"];
      chat["txtMsg"] = decryptAES(hiveChatHistory['sessionKey'], chats["txtMsg"]);
      chat["sender"] = chats["senderEmail"] == store!.state.user.email;
      
      if(chat["txtMsg"] != "") {
        // Check if any message with same Id exists
        dynamic msgChecker =
            hiveChatHistory['messages'].where((m) => m["id"] == chats["_id"]);
        if (msgChecker.length == 0) {
          Map<String, dynamic> chatHistory = new Map();
          chatHistory['sessionKey'] = hiveChatHistory['sessionKey'];
          chatHistory['messages'] = hiveChatHistory['messages'];
          chatHistory['messages'].add(chat);
          box.put(chats["receiverEmail"], chatHistory);
        }
        // Push all to messages
        store.dispatch(new UpdateMessagesAction(chat));
      }
    }
  });
}
