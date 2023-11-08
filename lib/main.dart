import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:provider/provider.dart';
import 'package:http/http.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:assets_audio_player/assets_audio_player.dart' hide Playlist;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:android_path_provider/android_path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'dart:isolate';
import 'dart:ui';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dart_vlc/dart_vlc.dart' hide Playlist;

import 'MainRoute.dart';

/////////////////////////////////
const debug = true;
void main() async {
  // setup logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    //print('${record.level.name}: ${record.time}: ${record.message}');
    // print blue colored message
    if (record.level == Level.INFO) {
      print(
          '\x1B[34m${record.level.name}: ${record.time}: ${record.message}\x1B[0m');
    } else if (record.level == Level.WARNING) {
      // print yellow colored message
      print(
          '\x1B[33m${record.level.name}: ${record.time}: ${record.message}\x1B[0m');
    } else if (record.level == Level.SEVERE) {
      // print red colored message
      print(
          '\x1B[31m${record.level.name}: ${record.time}: ${record.message}\x1B[0m');
    } else {
      print('${record.level.name}: ${record.time}: ${record.message}');
    }
  });

  // FlutterDownloader supports Android and IOS
  if (Platform.isAndroid || Platform.isIOS) {
    await FlutterDownloader.initialize(debug: debug, ignoreSsl: true);
  }

  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
    DartVLC.initialize();
  }
  // Change the default factory. On iOS/Android, if not using `sqlite_flutter_lib` you can forget
  // this step, it will use the sqlite version available on the system.
  databaseFactory = databaseFactoryFfi;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whale Music',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.grey,
      ),
      home: MainRoute(),
    );
  }
}
