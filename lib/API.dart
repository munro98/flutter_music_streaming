import 'dart:async';
import 'dart:convert' show json, utf8;
import 'dart:io';

import 'package:http/http.dart' as http;

import 'Track.dart';
import 'Playlist.dart';
import 'Settings.dart';

class Api {
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

  static Future<List<String>> fetchPlaylistsTracks(String id) async {
    print("API.fetchPlaylistsTracks:");

    final httpRequest =
        await http.get(Uri.http(Settings.url, 'api/playlist/' + id));

    List<String> tracks = [];

    if (httpRequest.statusCode != HttpStatus.ok) {
      throw Exception("Error http " + httpRequest.statusCode.toString());
      return tracks;
    }

    //final responseBody = await httpResponse.transform(utf8.decoder).join();
    final jsonResponse = json.decode(httpRequest.body); //responseBody

    print(jsonResponse);

    for (var d in jsonResponse['tracks']) {
      tracks.add(d['id']);
    }

    return tracks;
  }

  static Future<List<Track>> fetchTracks(
      String permalink, String sortOrder) async {
    print("API:fetchTracks " + Settings.url);
    //Client.userAgent = "testApp";

    final httpRequest = await http.get(Uri.http(Settings.url, 'api/track'));
    List<Track> tracks = <Track>[];

    if (httpRequest.statusCode != HttpStatus.ok) {
      throw Exception("Error http " + httpRequest.statusCode.toString());
    }

    final jsonResponse = json.decode(httpRequest.body); //responseBody

    for (var d in jsonResponse['data']) {
      //var lData = d['data'];
      print(d['artist']);

      var artists = d['artists'];
      if (artists != null) {
        //track.artists = artists;
      }

      var release_date = d['release_date'];
      if (release_date != null) {
        var dt = DateTime.parse(release_date);
        print(dt.toString());
      }

      String keys = d['name'] + " " + d['artist'];

      Track track = new Track(d['name'], d['_id'], d['file_path'],
          artist: d['artist'], search_keys: keys);

      tracks.add(track);
    }

    return tracks;
  }

  static Future<List<Playlist>> fetchPlaylists() async {
    print("API.fetchPlaylists:");
    //Client.userAgent = "testApp";

    final httpRequest = await http.get(Uri.http(Settings.url, 'api/playlist'));

    List<Playlist> playlist = <Playlist>[];

    if (httpRequest.statusCode != HttpStatus.ok) {
      throw Exception("Error http " + httpRequest.statusCode.toString());
      return playlist;
    }

    //final responseBody = await httpResponse.transform(utf8.decoder).join();
    final jsonResponse = json.decode(httpRequest.body); //responseBody

    for (var d in jsonResponse['data']['playlist']) {
      Playlist track = new Playlist(d['name'], d['_id']);
      playlist.add(track);
    }
    return playlist;
  }

  static Future<String> f(String id) async {
    print("API.fetchPlaylistTracks:");
    //Client.userAgent = "testApp";

    final httpRequest =
        await http.get(Uri.http(Settings.url, 'api/playlist/' + id));

    List<Playlist> playlist = <Playlist>[];

    if (httpRequest.statusCode != HttpStatus.OK) {
      throw Exception("Error http " + httpRequest.statusCode.toString());
      return "";
    }

    //final responseBody = await httpResponse.transform(utf8.decoder).join();
    //final jsonResponse = json.decode(httpRequest.body); //responseBody

    return httpRequest.body;
  }
}
