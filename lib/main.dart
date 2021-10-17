// @dart=2.12.0
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:ntruchat/screens/auth/Login.dart';
import 'package:ntruchat/screens/auth/Onboarding.dart';
import 'package:ntruchat/store/reducer.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Initial state/store values
final store = new Store<ChatState>(reducers,
    initialState: ChatState(
      errMsg: "",
      allUsers: null,
      user: null,
      activeUser: "",
      activeRoom: "",
      messages: [],
    ),
    middleware: [thunkMiddleware]);

Future<void> main() async {
  await Hive.initFlutter();
  await Hive.openBox('inbox');
  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  final Store<ChatState>? store;

  MyApp({this.store});

  @override
  Widget build(BuildContext context) {
    return new StoreProvider(
        store: store!,
        child: MaterialApp(
            title: 'NTRU-Chat',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            initialRoute: "onboarding",
            routes: {
              "onboarding": (BuildContext context) => Onboarding(),
              "login": (BuildContext context) => Login(),
            },
            home: SafeArea(
              child: Scaffold(),
            )));
  }
}
