// type of actions
import 'package:ntruchat/models/Models.dart';

// Types
enum Types { ClearError, ClearUser, ClearLog, ClearReg, IsAuthenticated }

// Update Error Action
class UpdateErrorAction {
  String _error;

  String get error => this._error;

  UpdateErrorAction(this._error);
}

// Update user action
class UpdateUserAction {
  User _user;

  User get user => this._user;

  UpdateUserAction(this._user);
}

// Update all User
class UpdateAllUserAction {
  List<UserData> _allUsers;

  get allUsers => this._allUsers;

  UpdateAllUserAction(this._allUsers);
}

// Update current room chat
class UpdateRoomAction {
  String _roomID;

  get roomID => this._roomID;

  UpdateRoomAction(this._roomID);
}

// Add message to messages
class UpdateMessagesAction {
  Map<String, dynamic> messages;

  get allMessages => this.messages;

  UpdateMessagesAction(this.messages);
}

// Add sent message to messages
class UpdateDispatchMsg {
  Map<String, dynamic> message;

  get updateMsg => this.message;

  UpdateDispatchMsg(this.message);
}

// Replace current state list of messages
class ReplaceListOfMessages {
  List<dynamic> messages;

  get listOfMessages => this.messages;

  ReplaceListOfMessages(this.messages);
}