import 'dart:async';
import 'dart:convert' show json, jsonDecode, utf8;
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path_lib;
import 'package:android_path_provider/android_path_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import 'Track.dart';
import 'AppDatabase.dart';
import 'Api.dart';
import 'FileUtil.dart';
import 'Settings.dart';

class Playlist {
  Playlist(String this.name, String this.id);

  //String sort_order; Title/Artist/Album/Playlist
  String name;
  String id;

  DateTime? created_date;
  DateTime? last_modified_date;
  DateTime? last_played_date;
  double? duration;
  int? size;
}

class PlaylistManager {
  static final log = Logger('PlaylistManager');

  static Future<bool> downloadPlaylists() async {
    try {
      List<Playlist> playlists = await Api.fetchPlaylists();

      // iterate each playlist and save it so local file storage
      playlists.forEach((el) async {
        String json = await Api.f(el.id);

        String? appDocPath = await FileUtil.getAppDocDir("/playlists");

        File file = File(appDocPath! + '/' + el.id + '.json');
        await file.writeAsString(json);
      });
    } catch (e) {
      print("PlaylistManager.downloadPlaylists: " + e.toString());
      return false;
    }
    return new Future<bool>(() => true);
  }

  //Note: needs local SQLite database to be synced with server DB
  //
  static Future<bool> downloadTracksInPlaylists(Playlist p) async {
    try {
      String? appDocPath = await FileUtil.getAppDocDir("/playlists");
      String? appMusicPath = await FileUtil.getAppMusicDir("/");

      File file = new File(appDocPath! + '/' + p.id + '.json');

      String json = await file.readAsString();
      var jsonData = jsonDecode(json);
      var ids = jsonData["tracks"];

      print(ids);

      ids.forEach((e) async {
        print('ID: ' + e['id']);
        Track track = await AppDatabase.fetchTrack(e['id']);
        print('path: ' + track.file_path);

        File trackPath = File(appMusicPath! + track.file_path);
        if (!trackPath.existsSync()) {
          PlaylistManager.download(track, appMusicPath);
        }
      });
    } catch (e) {
      print("PlaylistManager.downloadTracksInPlaylists: " + e.toString());
      return false;
    }

    return new Future<bool>(() => true);
  }

  static Future<List<Playlist>> fetchPlaylists() async {
    print("PlaylistManager:fetchPlaylists");

    List<Playlist> playlist = <Playlist>[];

    String? appDocPath = await FileUtil.getAppDocDir("/playlists");
    Directory appDocDir = new Directory(appDocPath!);
    // iterate all files in appDocPath
    List<FileSystemEntity> folders;
    folders = appDocDir.listSync(recursive: false, followLinks: false);

    Iterable<File> files = folders.whereType<File>();

    files.forEach((el) async {
      if (path_lib.basename(el.path).endsWith('.json')) {
        String jsonData = await el.readAsString();

        var jsonDecode = json.decode(jsonData);

        Playlist play = new Playlist(jsonDecode['id'], jsonDecode['id']);
        if (jsonDecode['name'] != null) {
          play.name = jsonDecode['name'];
        }

        playlist.add(play);
      }
    });

    return playlist;
  }

  static Future<List<String>> fetchPlaylistsTracks(String id) async {
    print("PlaylistManager:fetchPlaylistsTracks");
    List<String> tracks = [];

    try {
      String? appDocPath = await FileUtil.getAppDocDir("/playlists");
      File file = new File(appDocPath! + '/' + id + '.json');

      if (file.existsSync()) {
        String jsonData = await file.readAsString();
        var jsonDecode = json.decode(jsonData);

        print(jsonDecode);

        for (var d in jsonDecode['tracks']) {
          tracks.add(d['id']);
        }
      }
    } catch (e) {
      print("PlaylistManager:fetchPlaylistsTracks " + e.toString());
    }
    return tracks;
  }

  // TODO: Test
  static void download(Track track, String appMusicPath) async {
    var saveDir = await FileUtil.prepTrackDir(track);

    var url = Settings.urlHTTP + "/api/track/" + track.id;
    var id = await FlutterDownloader.enqueue(
      url: url,
      savedDir: saveDir,
      fileName: path_lib.basename(track.file_path),
      //showNotification: true,
      //openFileFromNotification: true,
    );
  }

  // TODO: Test
  static Future<bool> checkAvailableOnDisk(Track t) async {
    try {
      String? appMusicPath = await FileUtil.getAppMusicDir("/");

      File file = new File(appMusicPath! + '/' + t.file_path);

      if (file.existsSync()) {
        return true;
      }
    } catch (e) {
      print("PlaylistManager.downloadTracksInPlaylists: " + e.toString());
      return false;
    }

    return new Future<bool>(() => false);
  }

  static Future<List<Track>> fetchTracks() async {
    // TODO:
    print("AppDatabase: fetchTracks()");

    // Get a reference to the database.
/*
    Iterate all the monngoDB ids and generate track object from database data

    try {
      final Database db = await (database as Future<Database>);

      // Query the table
      final List<Map<String, dynamic>> maps = await db.query('track');

      List<Track> tracks = List.generate(maps.length, (i) {
        return Track(
          maps[i]['name'],
          maps[i]['id'],
          maps[i]['file_path'],
          artist: maps[i]['artist'],
        );
      });

      return tracks;
    } catch (e) {
      return [];
    }
    */
    return [];
  }
}
