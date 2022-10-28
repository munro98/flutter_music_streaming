import 'dart:async';
import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path/path.dart' as path_lib;

import 'dart:isolate';
import 'dart:ui';

import 'FileUtil.dart';
import 'Settings.dart';
import 'Track.dart';

ReceivePort _port = ReceivePort();

class _TaskInfo {
  final String? name;
  final String? link;

  String? taskId;
  int? progress = 0;
  DownloadTaskStatus? status = DownloadTaskStatus.undefined;

  _TaskInfo({this.name, this.link});
}

class _ItemHolder {
  final String? name;
  final _TaskInfo? task;

  _ItemHolder({this.name, this.task});
}

class DownloadManager {
  List<_TaskInfo>? _tasks;
  late List<_ItemHolder> _items;

  DownloadManager() {
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  static void downloadTrack(Track track) async {
    var permissionReady = await FileUtil.preparePermissions();
    if (permissionReady) {
      var saveDir = await FileUtil.prepTrackDir(track);

      var filePath = path_lib.join(saveDir, path_lib.basename(track.file_path));
      print("downloading to: " + filePath);

      var checkDuplicate = File(filePath);

      if (checkDuplicate.existsSync()) {
        //do nothing
      } else {
        //download
        var url = Settings.urlHTTP + "/api/track/" + track.id;
        var id = await FlutterDownloader.enqueue(
          url: url,
          savedDir: saveDir,
          fileName: path_lib.basename(track.file_path),
          //showNotification: true,
          //openFileFromNotification: true,
        );
      }
    }
  }
}
