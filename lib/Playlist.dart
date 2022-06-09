import 'dart:async';
import 'dart:convert' show json, jsonDecode, utf8;
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path_lib;
import 'package:android_path_provider/android_path_provider.dart';
import 'package:path_provider/path_provider.dart';

import 'Track.dart';
import 'AppDatabase.dart';
import 'Api.dart';
import 'FileUtil.dart';

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
  static Future<bool> downloadPlaylists() async {
    try {
      List<Playlist> playlists = await Api.fetchPlaylists();

      // iterate each playlist and save it so local storage
      playlists.forEach((el) async {
        String json = await Api.f(el.id);

        //File file = File(path! + '/' + el.id + '.json');
        String? appDocPath = await FileUtil.getAppDocDir("/playlists");
        //print(appDocDir);
        File file = File(appDocPath! + '/' + el.id + '.json');
        await file.writeAsString(json);
      });
    } catch (e) {
      print("PlaylistManager.downloadPlaylists: " + e.toString());
      return false;
    }
    return new Future<bool>(() => true);
  }

  //Note: requires Local SQLite database to be synced with server DB
  static Future<bool> downloadTracksInPlaylists(Playlist p) async {
    // TODO:
    try {
      String? appDocPath = await FileUtil.getAppDocDir("/playlists");
      File file = new File(appDocPath! + '/' + p.id + '.json');

      String json = await file.readAsString();
      var jsonData = jsonDecode(json);
      var ids = jsonData["tracks"];

      print(ids);

      ids.forEach((e) async {
        print('ID: ' + e['id']);
        Track track = await AppDatabase.fetchTrack(e['id']);
        print('path: ' + track.file_path);
        /*
        File trackPath = File(trackRoot! + track.file_path);
        if (!trackPath.existsSync()) {
          PlaylistManager.download(track);
        }
        */
      });
    } catch (e) {
      print("PlaylistManager.downloadTracksInPlaylists: " + e.toString());
      return false;
    }

    return new Future<bool>(() => true);
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

  static void download(Track track) {}
}
