import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ntruchat/main.dart';
import 'package:ntruchat/store/actions/types.dart';
import 'package:ntruchat/store/reducer.dart';
import 'package:uuid/uuid.dart';

import 'package:socket_io_client/socket_io_client.dart';

Future<void> onUniqueChat({
  Store<ChatState> store,
  Socket socket,
  senderEmail,
  receiverEmail,
}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Remove uniqueRooms
  // prefs.remove("_uniqueRooms");

  dynamic uniqueRoomsGetter = prefs.get("_uniqueRooms");
  dynamic uniqueRooms =
      (uniqueRoomsGetter == null) ? [] : json.decode(uniqueRoomsGetter);

  socket.emit('startUniqueChat',
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
      store.dispatch(UpdateRoomAction(user['roomID']));
    } else {
      uniqueRooms.add(mobileRoom);
      prefs.setString("_uniqueRooms", json.encode(uniqueRooms));
      store.dispatch(UpdateRoomAction(user['roomID']));

      // Start New Chat
      socket.emit('joinTwoUsers', {'roomID': user['roomID']});
    }
  });
}

Future<void> onSend({
  Store<ChatState> store,
  Socket socket,
  String txtMsg,
  String senderEmail,
  String receiverEmail,
}) {
  if (txtMsg == "") {
  } else {
    final now = new DateTime.now();
    // String formatedTime = DateFormat('yMd').format(now);
    dynamic formatedTime = DateTime.now().toUtc().microsecondsSinceEpoch;

    Map<String, dynamic> composeMsg = new Map();
    composeMsg['_id'] = Uuid().v4();
    composeMsg['roomID'] = store.state.activeRoom;
    composeMsg['txtMsg'] = txtMsg;
    composeMsg['receiverEmail'] = receiverEmail;
    composeMsg['senderEmail'] = senderEmail;
    composeMsg['time'] = formatedTime;
    composeMsg['sender'] = true;

    store.dispatch(new UpdateMessagesAction(composeMsg));

    socket.emit('sendTouser', composeMsg);
  }
}

Future<void> loadUniqueChats(
    {Store store,
    Socket socket,
    String currentUserEmail,
    String otherUser}) async {
  Map<String, dynamic> ChatDetails = new Map();
  ChatDetails["senderEmail"] = currentUserEmail;
  ChatDetails["receiverEmail"] = otherUser;

  socket.emit('load_user_chats', ChatDetails);
}

Future<void> groupUniqueChats({
  Store store,
  Socket socket,
}) {
  socket.on("loadUniqueChat", (chats) {
    List<dynamic> uniqueMessages = [];

    if (chats.isEmpty) {
      return;
    } else {
      Map<String, dynamic> chat = new Map();
      chat["id"] = chats["_id"];
      chat["roomID"] = chats["roomID"];
      chat["senderEmail"] = chats["senderEmail"];
      chat["receiverEmail"] = chats["receiverEmail"];
      chat["time"] = chats["time"];
      chat["txtMsg"] = chats["txtMsg"];
      chat["sender"] = chats["senderEmail"] == store.state.user.email;

      // Push all to messages
      store.dispatch(new UpdateMessagesAction(chat));

      List<dynamic> allMessages = store.state.messages;

      // You can regroup buy date and update the opened messages
      // and dispatch to replace existing state messages
    }
  });
}
