import 'dart:async';
import 'dart:convert' show json, utf8;
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

import 'Track.dart';

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
  Future<bool> downloadPlaylists() {
    // TODO:
    return new Future<bool>(() => true);
  }

  Future<bool> downloadTracksInPlaylists() {
    // TODO:
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
}
