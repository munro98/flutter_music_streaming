

import 'dart:async';
import 'dart:convert' show json, utf8;
import 'dart:io';

import 'package:http/http.dart' as http;

class Track {
  Track(String this.name, String this.id, String this.file_path, {
    String this.artist = "",String this.artists="", bool this.is_active = true, bool this.is_missing = false, bool this.is_downloaded = false,
    int this.play_count = 0, int this.track = 0, int this.track_of = 0, int this.disk = 0, int this.disk_of = 0,
    String this.album = "", int this.duration = 0, int size = 0, String format = "",
    String genre = "", int year = 0, String release_date = "", String added_date = "", String last_played_date = "" 
    
    });
  
  String name;
  String file_path;
  String id;
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
      'year' : year,
      'genre' : genre,
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



class Api {

  static final String url = '192.168.0.121:8080';

  static Future<List<Track>> fetchTracks (String permalink, String sortOrder) async {

    print("fetching tracks");
    //Client.userAgent = "testApp";

    final httpRequest =
      await http.get(Uri.http(url, 'api/track'));


    //final httpResponse = await httpRequest.close();

    List<Track> tracks = <Track>[];

    if (httpRequest.statusCode != HttpStatus.OK) {
      return tracks;
    }

    //final responseBody = await httpResponse.transform(utf8.decoder).join();
    final jsonResponse = json.decode(httpRequest.body);//responseBody

    

    for (var d in jsonResponse['data']) {
      //var lData = d['data'];
      print(d['artist']);

      var artists =  d['artists'];
      if (artists != null) {
        //track.artists = artists;
      }

      //DateTime.parse(d['release_date'])


      Track track = new Track(d['name'], d['_id'], 
       d['file_path'], artist: d['artist']);
      //
      
      
      tracks.add(track);


    };

    return tracks;

  }
  
}