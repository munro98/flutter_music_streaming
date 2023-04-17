import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart';

import 'package:path/path.dart' as path_lib;
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:ui';

import 'widgets/TextFieldInput.dart';

class Settings {
  static String url = "192.168.50.21:3000";
  static String user = "";
  static String password = "";

  // must be set when changing the url
  static String urlHTTP = "http://192.168.50.21:3000/";

  static Future<void> loadFromPrefs() async {
    print("Settings.loadFromPrefs");
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    String? urlS = prefs.getString('url');
    if (urlS != null) {
      Settings.url = urlS;
    }
    String? urlHTTPStr = prefs.getString('urlHTTP');
    if (urlHTTPStr != null) {
      Settings.urlHTTP = urlHTTPStr;
    }

    print("Settings.loadFromPrefs: " + Settings.url);
    print("Settings.loadFromPrefs: " + Settings.urlHTTP);
  }
}

class SettingsRoute extends StatefulWidget {
  const SettingsRoute();

  @override
  SettingsRouteState createState() => SettingsRouteState();
}

class SettingsRouteState extends State<SettingsRoute> {
  late String serverUrl;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _localLibraryController = TextEditingController();

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    // read the server url from the database
    super.initState();

    _prefs.then((prefs) {
      String? urlS = prefs.getString('url');
      if (urlS != null) {
        _urlController.text = urlS;
        Settings.url = urlS;
      }
      String? urlHTTPStr = prefs.getString('urlHTTP');
      if (urlHTTPStr != null) {
        Settings.urlHTTP = urlHTTPStr;
      }
      String? userS = prefs.getString('user');
      if (userS != null) {
        _userController.text = userS;
        Settings.user = userS;
      }
      String? passwordS = prefs.getString('password');
      if (passwordS != null) {
        _passwordController.text = passwordS;
        Settings.password = passwordS;
      }
    });

    print("Settings.initState: Init settings state");
  }

  void _saveSettings() async {
    print("Settings.Save");
    final SharedPreferences prefs = await _prefs;
    prefs.setString('url', _urlController.text).then((bool success) {});
    prefs.setString('user', _userController.text);
    prefs.setString('password', _passwordController.text);

    Settings.url = _urlController.text;
    Settings.urlHTTP = "http://" + _urlController.text;
    prefs.setString('urlHTTP', Settings.urlHTTP).then((bool success) {});

    print("Settings._saveSettings: " + Settings.url);
    print("Settings._saveSettings: " + Settings.urlHTTP);
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
                        textEditingController: _urlController,
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
                      child: Text("Save"),
                      style: TextButton.styleFrom(
                        primary: Color.fromARGB(255, 88, 134, 34),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () => {_saveSettings()},
                    )
                  ]))),
    );
  }
}
