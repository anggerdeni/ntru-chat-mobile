import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:ntruchat/store/actions/authActions.dart';

import '../../main.dart';

class Onboarding extends StatefulWidget {
  @override
  _OnboardingState createState() => new _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final LocalStorage storage = new LocalStorage('localstorage_app');

  @override
  void initState() {
    super.initState();
    new Future.delayed(Duration(seconds: 1), () {
      store
          .dispatch(loadUser(storage: storage, store: store, context: context));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("images/welcome.png"),
              fit: BoxFit.fitHeight,
            ),
          ),
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [],
            ),
          )),
    );
  }
}
