import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ntruchat/main.dart';
import 'package:ntruchat/models/Models.dart';
import 'package:ntruchat/screens/inbox/Inbox.dart';
import 'package:ntruchat/store/actions/types.dart';
import 'package:ntruchat/store/reducer.dart';
import 'package:ntruchat/constants/constants.dart';
import 'package:ntruchat/helpers/string_helper.dart';
import 'package:socket_io_client/socket_io_client.dart';

class UsersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: NTRUChatList(),
    );
  }
}

class NTRUChatList extends StatefulWidget {
  NTRUChatList({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _NTRUChatListState createState() => new _NTRUChatListState();
}

class _NTRUChatListState extends State<NTRUChatList> {
  Socket socket;

  @override
  void initState() {
    super.initState();
    socketServer();

    // Emit to Get all users in Database
    User currentUser = store.state.user;
    socket.emit("_getUsers", {'senderEmail': currentUser.email});

    // Gotten users to store
    socket.on("_allUsers", (allUsers) {
      List<UserData> users = [];

      for (var u in allUsers) {
        UserData _users =
            UserData(u['_id'], u['email'], u['name'], u['pubkey']);
        users.add(_users);
      }

      users.where((user) => user.email == store.state.user.email).toList();

      store.dispatch(new UpdateAllUserAction(users));
    });
  }

  // Socket Connection
  void socketServer() {
    try {
      // Configure socket transports must be sepecified
      socket = io(GlobalConstants.backendUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      // Connect to websocket
      socket.connect();

      // Handle socket events
      socket.on('connect', (_) => print('connect: ${socket.id}'));
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    User currentUser = store.state.user;
    return Material(
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Color(0xFF1EA955),
            leading: CircleAvatar(
              backgroundColor: Color(0xFFEEFFB3),
              radius: 10,
              child: Text(
                getInitialCharFromWords(currentUser.name),
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(currentUser.name, style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
          body: Container(
            child: Column(children: [
              StoreConnector<ChatState, List<UserData>>(
                  converter: (store) => store.state.allUsers,
                  onWillChange: (prev, next) {},
                  builder: (_, allUsers) {
                    if (allUsers == null) {
                      return Container(
                          child: Center(
                        child: Text("Loading Users..."),
                      ));
                    }

                    List<dynamic> filteredUsers = allUsers
                        .where((user) => user.email != store.state.user.email)
                        .toList();

                    return StoreConnector<ChatState, User>(
                        converter: (store) => store.state.user,
                        onWillChange: (prev, next) {},
                        builder: (_, user) {
                          return Container(
                              padding: const EdgeInsets.only(top: 10),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredUsers.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return InkWell(
                                      splashColor: null,
                                      onTap: () {
                                        socket.close();

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => Inbox(
                                                    senderMe: user.email,
                                                    receiver:
                                                        filteredUsers[index]
                                                            .email,
                                                    receiverPubkey:
                                                        filteredUsers[index]
                                                            .pubkey,
                                                    receiverName:
                                                        filteredUsers[index]
                                                            .name  
                                                  )),
                                        );
                                      },
                                      child: Ink(
                                          child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: null,
                                          child: Text(filteredUsers[index]
                                              .name
                                              .substring(0, 2)
                                              .toUpperCase()),
                                        ),
                                        title: Text(filteredUsers[index].name),
                                        subtitle: Text(
                                          filteredUsers[index].email,
                                          style: TextStyle(fontSize: 12.0),
                                        ),
                                      )));
                                },
                              ));
                        });
                  }),
            ]),
          ),
        ),
      ),
    );
  }
}
