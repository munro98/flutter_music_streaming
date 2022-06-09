import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path_lib;

import 'package:android_path_provider/android_path_provider.dart';
import 'package:path_provider/path_provider.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class FileUtil {
  static bool _permissionReady = false;
  static bool _isLoading = true;
  //static late String _localPath;

  static Future<bool> _preparePermissions() async {
    return await _checkPermission();
  }

  static Future<bool> _checkPermission() async {
    if (Platform.isIOS) return true;

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    }
    return false;
  }

  static Future<String?> getAppMusicDir(String filePath) async {
    if (!_permissionReady) {
      _permissionReady = await _preparePermissions();
    }

    try {
      String appDocPath;
      if (Platform.isAndroid) {
        appDocPath =
            await AndroidPathProvider.musicPath + "/Whale Music" + filePath;
      } else if (Platform.isIOS) {
        appDocPath = (await getApplicationDocumentsDirectory()).absolute.path +
            "/Whale Music" +
            filePath;
      } else {
        appDocPath = "";
      }

      final savedDir = Directory(appDocPath);
      bool hasExisted = await savedDir.exists();
      if (!hasExisted) {
        savedDir.create();
      }
      return appDocPath;
    } catch (e) {
      print(e);
    }
  }

  static Future<String?> getAppDocDir(String filePath) async {
    if (!_permissionReady) {
      _permissionReady = await _preparePermissions();
    }

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path + filePath;
    final savedDir = Directory(appDocPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
    return appDocPath;
  }
}
