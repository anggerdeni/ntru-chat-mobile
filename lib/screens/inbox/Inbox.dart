import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ntruchat/main.dart';
import 'package:ntruchat/models/Models.dart';
import 'package:ntruchat/store/actions/chatActions.dart';
import 'package:ntruchat/store/actions/types.dart';
import 'package:ntruchat/store/reducer.dart';
import 'package:ntruchat/constants/constants.dart';
import 'package:ntruchat/helpers/string_helper.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:hive/hive.dart';

class Inbox extends StatefulWidget {
  Inbox(
      {Key key,
      @required this.senderMe,
      @required this.receiver,
      @required this.receiverPubkey})
      : super(key: key);

  final String senderMe;
  final String receiver;
  final String receiverPubkey;

  @override
  _InboxState createState() => new _InboxState(
      senderMe: this.senderMe,
      receiver: this.receiver,
      receiverPubkey: this.receiverPubkey);
}

class _InboxState extends State<Inbox> {
  Socket socket;

  String senderMe;
  String receiver;
  String receiverPubkey;

  static const _boxName = 'inbox';

  _InboxState(
      {@required this.senderMe,
      @required this.receiver,
      @required this.receiverPubkey});

  // Set the Text Message
  String _txtMsg = "";

  var txtController = TextEditingController();

  @override
  void initState() async {
    super.initState();
    await Hive.openBox(_boxName);

    // Reset Messages
    store.state.messages.clear();

    // Connect to socket
    socketServer();
  }

  // Socket connection
  void socketServer() {
    try {
      var box = Hive.box(_boxName);
      if (box.get(this.receiver) == null) {
        box.put(
          this.receiver,
          ChatHistory()
            ..sessionKey = 'QUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUE='
            ..messages = []
        );
      }
      // Configure socket transports must be sepecified
      socket = io(GlobalConstants.backendUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      // Connect to websocket
      socket.connect();

      // Handle socket events
      socket.on('connect', (_) => print('connect: ${socket.id}'));
      store.dispatch(onUniqueChat(
        store: store,
        socket: socket,
        senderEmail: this.senderMe,
        receiverEmail: this.receiver,
      ));

      // Receiving messages
      socket.on('dispatchMsg', (data) {
        Map<String, dynamic> message = new Map();
        message["id"] = data["_id"];
        message["roomID"] = data["roomID"];
        message["senderEmail"] = data["senderEmail"];
        message["receiverEmail"] = data["receiverEmail"];
        message["txtMsg"] = data["txtMsg"];
        message["sender"] = data["sender"] == store.state.activeUser;

        store.dispatch(new UpdateDispatchMsg(message));
      });

      // Load Unique User Chat(s)
      store.dispatch(loadUniqueChats(
          socket: socket,
          store: store,
          currentUserEmail: store.state.user.email,
          otherUser: this.receiver));

      // Group P2P unique chats
      store.dispatch(groupUniqueChats(socket: socket, store: store));
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    User currentUser = store.state.user;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF1EA955),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  getInitialCharFromWords(currentUser.name),
                  style: TextStyle(
                    fontSize: 10,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text("cUser", style: TextStyle(fontSize: 14)),
              ),
              Padding(
                padding: EdgeInsets.only(left: 2),
                child: Icon(
                  EvilIcons.user,
                  color: Colors.white,
                ),
              )
            ],
          ),
          actions: <Widget>[
            Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {},
                  child: Icon(
                    Ionicons.ios_videocam,
                    size: 30.0,
                  ),
                )),
            Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {},
                  child: Icon(
                    Icons.more_vert,
                  ),
                )),
          ],
        ),
        body: Stack(
          children: <Widget>[
            StoreConnector<ChatState, List<dynamic>>(
                converter: (store) => store.state.messages,
                builder: (_, cMsgs) {
                  return ListView.builder(
                    itemCount: cMsgs.length,
                    shrinkWrap: true,
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      String txtMsg = cMsgs[index]["txtMsg"];
                      bool sender = cMsgs[index]["sender"];

                      return Container(
                        padding: EdgeInsets.only(
                            left: 14, right: 14, top: 10, bottom: 10),
                        child: Align(
                          alignment: (sender == true
                              ? Alignment.topLeft
                              : Alignment.topRight),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: (sender == true
                                  ? Color(0xFF1EA955)
                                  : Colors.grey.shade200),
                            ),
                            padding: EdgeInsets.all(16),
                            child: Text(
                              txtMsg,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: sender == true
                                      ? Colors.white
                                      : Colors.black87),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
                height: 60,
                width: double.infinity,
                color: Colors.white,
                child: Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.lightBlue,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Expanded(
                      child: TextField(
                          controller: txtController,
                          decoration: InputDecoration(
                              hintText: "Write message...",
                              hintStyle: TextStyle(color: Colors.black54),
                              border: InputBorder.none),
                          onChanged: (txtMsg) {
                            if (txtMsg.length > 0) {
                              setState(() {
                                _txtMsg = txtMsg;
                              });
                            }
                          }),
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    FloatingActionButton(
                      onPressed: () {
                        store.dispatch(onSend(
                            socket: socket,
                            store: store,
                            txtMsg: _txtMsg,
                            senderEmail: this.senderMe,
                            receiverEmail: this.receiver));

                        // Reset the text Message
                        setState(() {
                          _txtMsg = "";
                        });

                        // Clear the TextField
                        txtController.clear();
                      },
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                      backgroundColor: Colors.blue,
                      elevation: 0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
