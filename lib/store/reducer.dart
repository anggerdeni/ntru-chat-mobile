import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:ntruchat/main.dart';
import 'package:ntruchat/models/Models.dart';
import 'actions/types.dart';

class ChatState {
  final String errMsg;

  // Authentication //
  bool isAuthenticated = false;
  final bool regLoading;
  final bool logLoading;
  final User user;
  final List<UserData> allUsers;

  // Chats
  final String activeUser;
  final String activeRoom;

  // Chat Messages
  final List<dynamic> messages;

  // Chat State
  ChatState({
    this.user,
    this.errMsg,
    this.isAuthenticated,
    this.regLoading,
    this.logLoading,
    this.allUsers,
    this.activeUser,
    this.activeRoom,
    this.messages,
  });

  ChatState copyWith({
    errMsg,
    bool isAuthenticated,
    User user,
    List<UserData> allUsers,
    String activeRoom,
    String activeUser,
    List<dynamic> messages,
  }) {
    return ChatState(
        errMsg: errMsg ?? this.errMsg,
        allUsers: allUsers ?? this.allUsers,
        activeUser: activeUser ?? this.activeUser,
        activeRoom: activeRoom ?? this.activeRoom,
        user: user ?? this.user,
        messages: messages ?? this.messages);
  }
}

// Authentication Reducer
ChatState authReducer(ChatState state, dynamic action) {

  // Push any error message
  if (action is UpdateErrorAction) {
    return state.copyWith(errMsg: action.error);
  }

  // update current user from Authentication
  if (action is UpdateUserAction) {
    return state.copyWith(user: action.user);
  }

  // Add users to users
  if (action is UpdateAllUserAction) {
    return state.copyWith(allUsers: action.allUsers);
  }

  // Update current unique Chat room
  if (action is UpdateRoomAction) {
    return state.copyWith(activeRoom: action.roomID);
  }

  if (action is UpdateMessagesAction) {
    List<dynamic> messages = state.messages;

    // Check if any message with same Id exists
    dynamic msgChecker =
        messages.where((m) => m["id"] == action.allMessages['id']);

    if (msgChecker.length == 0) {
      messages.add(action.allMessages);
      messages.sort((a, b) {
        int t1,t2;
        if(a['time'] is int) {t1 = a['time'];} else if (a['time'] is String) {t1 = int.parse(a['time']);} else {t1 = 0;}
        if(b['time'] is int) {t2 = b['time'];} else if (b['time'] is String) {t2 = int.parse(b['time']);} else {t2 = 0;}
        return t1 - t2;
      });
      return state.copyWith(messages: messages);
    }
  }

  if (action is UpdateDispatchMsg) {
    List<dynamic> messages = store.state.messages;

    // Check if any message with same Id exists
    dynamic msgChecker =
        messages.where((m) => m["id"] == action.updateMsg['id']);

    if (msgChecker.length == 0) {
      messages.add(action.updateMsg);
      messages.sort((a, b) {
        int t1,t2;
        if(a['time'] is int) {t1 = a['time'];} else if (a['time'] is String) {t1 = int.parse(a['time']);} else {t1 = 0;}
        if(b['time'] is int) {t2 = b['time'];} else if (b['time'] is String) {t2 = int.parse(b['time']);} else {t2 = 0;}
        return t1 - t2;
      });
      return state.copyWith(messages: messages);
    }
  }

  if (action is ReplaceListOfMessages) {
    return state.copyWith(messages: action.listOfMessages);
  }

  return state;
}

// Reset Reducers //
ChatState resetReducer(ChatState state, dynamic action) {
  switch (action) {
    case Types.ClearError:
      return state.copyWith(errMsg: "");
    case Types.IsAuthenticated:
      return state.copyWith(isAuthenticated: true);
  }
  return state;
}

// Combine Reducers
final reducers = combineReducers<ChatState>([authReducer, resetReducer]);
