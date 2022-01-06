import 'dart:async';
import 'dart:convert' show json, utf8;
import 'dart:io';


import 'Track.dart';
import 'Playlist.dart';
import 'package:http/http.dart' as http;


class Api {

  static final String url = '192.168.0.105:3000';

  /*
  static Future<List<Playlist>> fetchPlaylists () async {

    print("fetching playlists");

    final httpRequest =
    await http.get(Uri.http(url, 'api/playlist'));

    List<Playlist> playlists = <Playlist>[];

    if (httpRequest.statusCode != HttpStatus.OK) {
      return playlists;
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

      Playlist pl = new Playlist(d['name'], d['_id']);
      playlists.add(pl);
    };

    return playlists;

  }
  */

  static Future<List<String>> fetchPlaylistsTracks (String id) async {

    print("fetching playlists");

    final httpRequest =
    await http.get(Uri.http(url, 'api/playlist/'+id));

    List<String> tracks = [];

    if (httpRequest.statusCode != HttpStatus.OK) {
      return tracks;
    }

    //final responseBody = await httpResponse.transform(utf8.decoder).join();
    final jsonResponse = json.decode(httpRequest.body);//responseBody

    print(jsonResponse);

    for (var d in jsonResponse['tracks']) {
      tracks.add(d['id']);
    };

    return tracks;

  }


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
      
      tracks.add(track);
    };

    return tracks;

  }


  static Future<List<Playlist>> fetchPlaylists (String permalink, String sortOrder) async {

    print("fetching playlists");
    //Client.userAgent = "testApp";

    final httpRequest =
      await http.get(Uri.http(url, 'api/playlist'));

    List<Playlist> playlist = <Playlist>[];

    if (httpRequest.statusCode != HttpStatus.OK) {
      return playlist;
    }

    //final responseBody = await httpResponse.transform(utf8.decoder).join();
    final jsonResponse = json.decode(httpRequest.body);//responseBody

    for (var d in jsonResponse['data']['playlist']) {

      Playlist track = new Playlist(d['name'], d['_id']);
      playlist.add(track);


    };

    return playlist;

  }
  
}