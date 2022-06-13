import 'dart:async';
import 'dart:convert' show json, utf8;
import 'dart:io';

import 'package:http/http.dart' as http;

class Track {
  Track(String this.name, String this.id, String this.file_path,
      {String this.artist = "",
      String this.artists = "",
      bool this.is_active = true,
      bool this.is_missing = false,
      bool this.is_downloaded = false,
      int this.play_count = 0,
      int this.track = 0,
      int this.track_of = 0,
      int this.disk = 0,
      int this.disk_of = 0,
      String this.album = "",
      int this.duration = 0,
      int size = 0,
      String format = "",
      String genre = "",
      int year = 0,
      String release_date = "",
      String added_date = "",
      String last_played_date = "",
      String oid = ""});

  String name;
  String file_path;
  String id; // mongoID
  String? oid; // sqliteID
  bool is_active;
  bool is_downloaded;
  bool? is_missing;
  int? play_count;
  DateTime? release_date;
  DateTime? added_date;
  int? year;
  DateTime? last_played_date;
  String? genre;
  String? album;
  int? track;
  int? track_of;
  int? disk;
  int? disk_of;
  String? format;
  int? duration;
  int? size;
  String artist;
  String? artists;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'file_path': file_path,
      'artist': artist,
      'release_date': release_date,
      'added_date': added_date,
      'last_played_date': last_played_date,
      'year': year,
      'genre': genre,
      'artists': artists,
      'is_active': is_active,
      'is_missing': is_missing,
      'is_downloaded': is_downloaded,
      'play_count': play_count,
      'track': track,
      'track_of': track_of,
      'disk': disk,
      'disk_of': disk_of,
      'album': album,
      'duration': duration,
      'size': size,
      'format': format,
    };
  }
}
