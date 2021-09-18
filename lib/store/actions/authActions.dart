import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import "package:redux/redux.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ntruchat/models/Models.dart';
import 'package:ntruchat/screens/auth/Login.dart';
import 'package:ntruchat/screens/home/UsersList.dart';
import 'package:ntruchat/store/actions/types.dart';
import 'package:ntruchat/store/reducer.dart';
import 'package:ntruchat/constants/constants.dart';
import 'package:ntruchat/cryptography/ntru.dart';
import 'dart:convert';

// Load user details
Future<void> loadUser(
    {Store<ChatState> store, BuildContext context, storage}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String _token = prefs.getString("apiToken") ?? null;

  final url = Uri.parse('${GlobalConstants.backendUrl}/login/user');
  Map<String, String> headers = {
    "Content-type": "application/json",
    "x-api-token": _token
  };

  Response response = await get(url, headers: headers);
  final statusCode = response.statusCode;

  if (statusCode == 400) {
    prefs.remove("apiToken");
    new Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Login()));
    });
  }

  if (statusCode == 200) {
    // User Info
    Map<String, dynamic> body = json.decode(response.body);
    User user =
        User(email: body['email'], name: body['name'], pubkey: body['pubkey']);
    store.dispatch(new UpdateUserAction(user));

    await Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => UsersList()));
    });
  }
}

// Login a user action
Future<void> login(
    {Store<ChatState> store,
    email,
    password,
    BuildContext context,
    storage}) async {
  final url = Uri.parse('${GlobalConstants.backendUrl}/login');
  Map<String, String> headers = {"Content-type": "application/json"};
  NTRU ntru = new NTRU();
  String data = '{"email": "' +
      email +
      '", "password": "' +
      password +
      '", "pubkey": "' +
      ntru.h.encodeCoefficientsToCommaSeparatedValue() +
      '"}';
  SharedPreferences prefs = await SharedPreferences.getInstance();

  Response response = await post(url, headers: headers, body: data);

  final statusCode = response.statusCode;

  if (statusCode != 200) {
    final body = json.decode(response.body);

    if (body['msg'] != "") {
      prefs.remove("apiToken");
      prefs.remove("privkey_f");
      prefs.remove("privkey_fp");
      store.dispatch(new UpdateErrorAction(body['msg']));
    }
  }

  if (statusCode == 200) {
    final body = json.decode(response.body);

    if (body['user'] != null) {
      store.dispatch(Types.ClearError);

      // Grab Response data
      User user = User(
          name: body["user"]["name"],
          email: body["user"]["email"],
          id: body["user"]["id"],
          pubkey: body["user"]["pubkey"]);

      store.dispatch(new UpdateUserAction(user));

      // Grab & Set token to localStorage
      String token = body['token'];
      await prefs.setString("apiToken", "$token");
      await prefs.setString("privkey_f",
          ntru.privateKey[0].encodeCoefficientsToCommaSeparatedValue());
      await prefs.setString("privkey_fp",
          ntru.privateKey[1].encodeCoefficientsToCommaSeparatedValue());

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => UsersList()));
    }
  }
}

// Register a user action
Future<void> register(
    {Store<ChatState> store,
    storage,
    name,
    email,
    password,
    cpassword,
    BuildContext context}) async {
  final url = Uri.parse('${GlobalConstants.backendUrl}/users');
  Map<String, String> headers = {"Content-type": "application/json"};
  NTRU ntru = new NTRU();
  String data = '{"email": "' +
      email +
      '", "password": "' +
      password +
      '", "name": "' +
      name +
      '", "cpassword": "' +
      cpassword +
      '", "pubkey": "' +
      ntru.h.encodeCoefficientsToCommaSeparatedValue() +
      '"}';

  Response response = await post(url, headers: headers, body: data);

  final statusCode = response.statusCode;

  SharedPreferences prefs = await SharedPreferences.getInstance();

  if (statusCode != 200) {
    final body = json.decode(response.body);
    if (body['msg'] != "") {
      prefs.remove("apiToken");
      store.dispatch(new UpdateErrorAction(body['msg']));
    }
  }

  if (statusCode == 200) {
    dynamic body = json.decode(response.body);
    if (body['user'] != null) {
      // Clear any error
      store.dispatch(Types.ClearError);

      // Grab Response data
      User user = User(
          name: body["user"]["name"],
          email: body["user"]["email"],
          pubkey: body["user"]["pubkey"],
          id: body["user"]["id"]);

      // Grab the token
      String token = body['token'];

      // Set token for localStorage
      await prefs.setString("apiToken", "$token");
      await prefs.setString("privkey_f",
          ntru.privateKey[0].encodeCoefficientsToCommaSeparatedValue());
      await prefs.setString("privkey_fp",
          ntru.privateKey[1].encodeCoefficientsToCommaSeparatedValue());

      store.dispatch(new UpdateUserAction(user));

      await Future.delayed(Duration(seconds: 3), () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => UsersList()));
      });
    }
  }
}

// Random String generator
String generateRandomString(int len) {
  var r = Random();
  const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  return List.generate(len, (index) => _chars[r.nextInt(_chars.length)]).join();
}
