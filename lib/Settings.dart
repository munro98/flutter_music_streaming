import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart';

import 'package:path/path.dart' as path_lib;

import 'dart:ui';

import 'widgets/TextFieldInput.dart';

class Settings {
  static String url = "192.168.0.105:3000";

  // must be set when changing the url
  static String urlHTTP = "http://192.168.0.105:3000";
}

class SettingsRoute extends StatefulWidget {
  const SettingsRoute();

  @override
  SettingsRouteState createState() => SettingsRouteState();
}

class SettingsRouteState extends State<SettingsRoute> {
  late String serverUrl;
  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _localLibraryController = TextEditingController();

  @override
  void initState() {
    // read the server url from the database
    super.initState();
    _serverController.text = Settings.url;
  }

  @override
  Widget build(BuildContext context) {
    // create a textBox that edits the server url

    return new DefaultTabController(
      length: 3,
      child: new Scaffold(
          appBar: new AppBar(
              title: Text("Settings"),
              bottom: new PreferredSize(
                  preferredSize: const Size.fromHeight(48.0),
                  child: new Container())),
          body: new Container(
              //height: 48.0,
              alignment: Alignment.center,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text("Server"),
                    TextFieldInput(
                        textEditingController: _serverController,
                        hintText: "Server Address",
                        textInputType: TextInputType.name),
                    TextFieldInput(
                        textEditingController: _userController,
                        hintText: "User Name",
                        textInputType: TextInputType.name),
                    TextFieldInput(
                        textEditingController: _passwordController,
                        hintText: "Password",
                        textInputType: TextInputType.visiblePassword),
                    TextButton(
                      child: Text("Login"),
                      style: TextButton.styleFrom(
                        primary: Color.fromARGB(255, 88, 134, 34),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () => {print("login")},
                    )
                  ]))),
    );
  }
}
