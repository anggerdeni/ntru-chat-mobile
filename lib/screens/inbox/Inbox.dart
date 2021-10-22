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
import 'package:ntruchat/cryptography/kem.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:hive/hive.dart';
import 'package:ntruchat/cryptography/aes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Inbox extends StatefulWidget {
  Inbox(
      {Key? key,
      @required this.senderMe,
      @required this.receiver,
      @required this.receiverPubkey,
      @required this.selfPubkey,
      @required this.receiverName})
      : super(key: key);

  final String? senderMe;
  final String? receiver;
  final String? receiverPubkey;
  final String? selfPubkey;
  final String? receiverName;

  @override
  _InboxState createState() => new _InboxState(
      senderMe: this.senderMe,
      receiver: this.receiver,
      receiverPubkey: this.receiverPubkey,
      selfPubkey: this.selfPubkey,
      receiverName: this.receiverName);
}

class _InboxState extends State<Inbox> {
  Socket? socket;
  String? senderMe;
  String? receiver;
  String? receiverPubkey;
  String? selfPubkey;
  String? receiverName;

  static const _boxName = 'inbox';

  _InboxState(
      {@required this.senderMe,
      @required this.receiver,
      @required this.receiverPubkey,
      @required this.selfPubkey,
      @required this.receiverName});

  // Set the Text Message
  String _txtMsg = "";

  var txtController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Reset Messages
    store.state.messages!.clear();

    // Connect to socket
    socketServer();
  }

  // Socket connection
  void socketServer() async {
    try {
      // Configure socket transports must be sepecified
      socket = io(GlobalConstants.backendUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      // Connect to websocket
      socket!.connect();
      // Handle socket events
      socket!.on('connect', (_) => print('connect: ${socket!.id}'));
      store.dispatch(onUniqueChat(
        store: store,
        socket: socket,
        senderEmail: this.senderMe,
        receiverEmail: this.receiver,
        receiverPubkey: this.receiverPubkey,
        selfPubkey: this.selfPubkey,
      ));

      var box = Hive.box(_boxName);
      var receiverBox = await box.get(this.receiver);
      Map<String, dynamic> chatHistory = new Map();
      if (receiverBox == null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String privF = prefs.getString('privkey_f')!;
        String privFp = prefs.getString('privkey_fp')!;

        List<String> kemProcess = generateSecretKey(this.selfPubkey!, privF, privFp, this.receiverPubkey!);
        chatHistory['sessionKey'] = kemProcess[0];
        print("${this.senderMe} initialize KEM for ${this.receiver} with encrypted session key ${chatHistory['sessionKey']}");
        socket!.emit('kem', {
          'senderEmail': this.senderMe,
          'receiverEmail': this.receiver,
          'receiverPubkey': this.receiverPubkey,
          'selfPubkey': this.selfPubkey,
          'encryptedKey': kemProcess[1]
        });
        chatHistory['messages'] = [];
        box.put(this.receiver, chatHistory);
      }
      var hiveChatHistory = box.get(this.receiver);

      // Receiving messages
      socket!.on('dispatchMsg', (data) async {
        print("${data["receiverEmail"]} received encrypted message from ${data["senderEmail"]}: ${data["txtMsg"]} - ${data["hash"]}");
        Map<String, dynamic> message = new Map();
        message["id"] = data["_id"];
        message["roomID"] = data["roomID"];
        message["senderEmail"] = data["senderEmail"];
        message["receiverEmail"] = data["receiverEmail"];
        message["txtMsg"] = decryptAES(hiveChatHistory['sessionKey'], data["txtMsg"]);
        message["time"] = data["time"];
        message["sender"] = data["sender"] == store.state.activeUser;

        if(message["txtMsg"] != "") {
          // Check if any message with same Id exists
          dynamic msgChecker =
              hiveChatHistory['messages'].where((m) => m["id"] == message["id"]);

          if (msgChecker.length == 0) {
            Map<String, dynamic> chatHistory = new Map();
            chatHistory['sessionKey'] = hiveChatHistory['sessionKey'];
            chatHistory['messages'] = hiveChatHistory['messages'];
            chatHistory['messages'].add(message);
            box.put(this.receiver, chatHistory);
          }
          store.dispatch(loadUniqueChats(
            socket: socket,
            store: store,
            currentUserEmail: store.state.user!.email!,
            otherUser: this.receiver!,));
          store.dispatch(new UpdateDispatchMsg(message));

          socket!.emit('readMsg', {'msgId': data["_id"]});
        }

      });

      socket!.on('kem', (data) async {
        if(this.senderMe == data['receiverEmail']) {
          var box = Hive.box(_boxName);
          Map<String, dynamic> chatHistory = new Map();
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String privF = prefs.getString('privkey_f')!;
          String privFp = prefs.getString('privkey_fp')!;
          chatHistory['sessionKey'] = decryptSecretKey(this.selfPubkey!, privF, privFp, this.receiverPubkey!, data['encryptedKey']);
          chatHistory['messages'] = [];
          box.put(this.receiver, chatHistory);
          print("${data['receiverEmail']} received KEM request from ${data['senderEmail']} with encrypted session key ${chatHistory['sessionKey']}");
        }
      });

      // Load Unique User Chat(s)
      store.dispatch(loadUniqueChats(
          socket: socket,
          store: store,
          currentUserEmail: store.state.user!.email!,
          otherUser: this.receiver!));
      List<dynamic> listOfMessages = [];
      for (int i = 0; i < hiveChatHistory['messages'].length; i++) {
        Map<String, dynamic> chat = new Map();
        chat["id"] = hiveChatHistory['messages'][i]["_id"];
        chat["roomID"] = hiveChatHistory['messages'][i]["roomID"];
        chat["senderEmail"] = hiveChatHistory['messages'][i]["senderEmail"];
        chat["receiverEmail"] = hiveChatHistory['messages'][i]["receiverEmail"];
        chat["txtMsg"] = hiveChatHistory['messages'][i]["txtMsg"];
        chat["hash"] = hiveChatHistory['messages'][i]["hash"];
        chat["time"] = hiveChatHistory['messages'][i]["time"];
        chat["sender"] = hiveChatHistory['messages'][i]["senderEmail"] ==
            store.state.user!.email;

        dynamic msgChecker =
            hiveChatHistory['messages'].where((m) => m["id"] == chat["id"]);

        if (msgChecker.length == 0) {
          Map<String, dynamic> chatHistory = new Map();
          chatHistory['sessionKey'] = hiveChatHistory['sessionKey'];
          chatHistory['messages'] = hiveChatHistory['messages'];
          chatHistory['messages'].add(chat);
          listOfMessages.add(chat);
        }
      }
      store.dispatch(new ReplaceListOfMessages(listOfMessages));

      // Group P2P unique chats
      store.dispatch(groupUniqueChats(socket: socket, store: store, receiverPubkey: this.receiverPubkey, selfPubkey: this.selfPubkey, senderEmail: this.senderMe));
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: Color(0xFFEEFFB3),
                child: Text(
                  getInitialCharFromWords(receiverName),
                  style: TextStyle(
                    fontSize: 10,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(receiverName ?? '', style: TextStyle(fontSize: 14)),
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
        ),
        body: Stack(
          children: <Widget>[
            StoreConnector<ChatState, List<dynamic>>(
                converter: (store) => store.state.messages!,
                builder: (_, cMsgs) {
                  return SingleChildScrollView(
                    reverse: true,
                    child: ListView.builder(
                      itemCount: cMsgs.length,
                      shrinkWrap: true,
                      padding: EdgeInsets.only(top: 10, bottom: 70),
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
                    ),
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
                    SizedBox(
                      width: 15,
                    ),
                    Expanded(
                      child: TextField(
                          controller: txtController,
                          decoration: InputDecoration(
                              hintText: "Tulis Pesan",
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
                            senderEmail: this.senderMe!,
                            receiverEmail: this.receiver!,
                            selfPubkey: this.selfPubkey,
                            receiverPubkey: this.receiverPubkey));

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
