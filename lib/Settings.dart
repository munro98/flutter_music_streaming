import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart';

import 'package:path/path.dart' as path_lib;

import 'dart:ui';

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

  @override
  void initState() {
    // read the server url from the database
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // create a textBox that edits the server url

    throw UnimplementedError();
  }
}
