import 'dart:async';
import 'dart:convert' show json, utf8;
import 'dart:io';

import 'Track.dart';
import 'Playlist.dart';
import 'package:http/http.dart' as http;


class Api {

  static final String url = '192.168.0.121:8080';

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


  static Future<List<Track>> fetchTracks (String permalink, String sortOrder) async {

    print("fetching tracks");
    //Client.userAgent = "testApp";

    //'sort': 'new'
    //final uri = Uri.https(url, '/r/opengl/comments.json', {}); // new hot top best rising controversial gilded

    //final uri = Uri.https(url, '$permalink', {'sort': sortOrder, 'raw_json' : '1' }); // 'best' /.json
    //final httpRequest = await Client.getUrl(uri);
    final httpRequest =
      await http.get(Uri.http(url, 'api/track'));


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
       d['file_path'], artist: d['artist'], is_active: d['active'], play_count: d['play_count']);
      //
      
      tracks.add(track);
    };

    return tracks;

  }
  
}