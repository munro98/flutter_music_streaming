import 'dart:collection';
import 'dart:math';
import 'dart:isolate';
import 'dart:async';
import 'dart:io';

import 'package:flutter_music_app/AppDatabase.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';

import 'package:assets_audio_player/assets_audio_player.dart' hide Playlist;
import 'package:android_path_provider/android_path_provider.dart';
import 'package:path_provider/path_provider.dart';

import 'Track.dart';

import 'AppDatabase.dart';
import 'API.dart';
import 'Playlist.dart';

import 'Playlist.dart';

enum PlayContext { all, playlist }

enum LoopMode { none, one, all }

const String STREAM_URL = "http://192.168.0.105:3000/api/track/";

class Player {
  //static int THREASH = 512;

  Player();

  AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();

  //Track current;
  Track? current;
  int current_ind = 0;

  //List<Playlist> playlists
  //Playlist currentSelected

  PlayContext _vs = PlayContext.all;

  List<Track> _tracks = [];
  List<Track> shuffle_tracks = [];

  bool isLooping = false;
  bool isShuffle = false;

  //bool isLargePlaylist = false;
  //DoubleLinkedQueue < int > queue; // 128 max length
  //Set < int > set;

  @override
  void initState() {
    assetsAudioPlayer.playlistAudioFinished.listen((Playing playing) {
      print(" music finished");

      //if (assetsAudioPlayer.isPlaying.value) {
      //  skip_next();
      //}
    });
  }

  void loadPlaylist(Playlist playlist) async {
    if (playlist.id == "#ALL#") {
      /*
      final tracks2 = await AppDatabase.fetchTracks();
      
      setState(() {
      _vs = ViewState.all;
      _tracks = tracks2;
      _pagingController.refresh();
    });
    */

    } else {
      final tracksids = await Api.fetchPlaylistsTracks(playlist.id);
      final tracks2 = await AppDatabase.fetchPlaylistTracks(
          tracksids); //fetchTracksByPlaylist

      //setState(() {
      _vs = PlayContext.playlist;
      _tracks = tracks2;
      //_pagingController.refresh();
      //});

    }
  }

  void toggleShuffle() {
    isShuffle = !isShuffle;

    if (isShuffle) {
      //if (tracks.length < THREASH) {
      current_ind = 0;
      shuffle_tracks = _tracks;
      shuffle_tracks.shuffle();
      //  isLargePlaylist = false;

      //} else {
      //  isLargePlaylist = true;
      //}
    }
  }

  Future<Track> getNextTrack() async {
    if (current != null) {
      if (_vs == PlayContext.all) {
        Track c = current as Track;
        print(
            "________________________________________________________________________oid " +
                c.name);
        print(
            "________________________________________________________________________oid " +
                c.oid.toString());

        Track next = await AppDatabase.fetchNextTrack(c.oid as String, "");
        print("________________________________________" + next.name);
        return next;
      } else if (_vs == PlayContext.playlist) {
        if (isShuffle) {
          //if (!isLargePlaylist) {

          var t = shuffle_tracks[current_ind];
          current_ind = current_ind + 1 % shuffle_tracks.length;
          return t;
          /*
          } else {

            var rng = new Random();
            int new_ind = rng.nextInt(tracks.length);

            int i = 0;
            while (i < 4) {
              if (!set.contains(new_ind)) {
                break;
              }
              new_ind = rng.nextInt(tracks.length);

            }

            if (queue.length == 128) {

              int front = queue.iterator.current;
              queue.removeFirst();
              set.remove(front);

              queue.addLast(new_ind);

            }

            return tracks[new_ind];
          }
          */

        } else {
          if (current_ind == _tracks.length - 1) {
            current_ind = 0;
          } else {
            current_ind = current_ind + 1;
          }

          return _tracks[current_ind];
        }
      }
    }
    throw Exception();
  }

  Future<Track> getPrevTrack() async {
    if (current != null) {
      if (_vs == PlayContext.all) {
        if (current != null) {
          Track c = current as Track;
          Track next = await AppDatabase.fetchPrevTrack(c.oid as String, "");
          return next;
        }
      } else if (_vs == PlayContext.playlist) {
        int ind = current_ind - 1;
        if (ind < 0) {
          ind = shuffle_tracks.length - 1;
        }

        var t = shuffle_tracks[ind];
        current_ind = ind;
        return t;
      }
    }
    throw Exception();
  }

  // moving functions

  void playOrPause() {
    assetsAudioPlayer.playOrPause();
  }

  void playTrackStream(Track track) async {
    current = track;

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        assetsAudioPlayer.stop();
        await assetsAudioPlayer.open(Audio.network(STREAM_URL + track.id));

        //assetsAudioPlayer.open(
        //  Audio("assets/DROELOE - Taking Flight.flac"),
        //);

        print('playing!');
      } catch (t) {
        print('could not play!');
      }
    } else if (Platform.isWindows) {}
  }

  void playFile(Track track) async {
    current = track;

    if (Platform.isAndroid) {
      try {
        assetsAudioPlayer.stop();

        var externalStorageDirPath =
            await AndroidPathProvider.musicPath + "/Whale Music";

        //final bytes = await readBytes(Uri.parse("kUrl1"));
        final file = File('${externalStorageDirPath}/${track.file_path}');

        //await file.writeAsBytes(bytes);
        if (file.existsSync()) {
          await assetsAudioPlayer.open(Audio.network(file.path));
          print('Player.playFile: playing!');
        } else {
          print('Player.playFile: could not play!');
        }
        //assetsAudioPlayer.open(
        //  Audio("assets/DROELOE - Taking Flight.flac"),
        //);
      } catch (t) {
        print('Player.playFile: could not play!');
      }
    } else if (Platform.isWindows) {}
  }

  void play_pause() {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      assetsAudioPlayer.playOrPause();
    } else if (Platform.isWindows) {}
  }

  void skip_next() async {
    print('Player: skip_next()!');

    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      assetsAudioPlayer.stop();
      try {
        Track t = await getNextTrack();
        current = t;

        await assetsAudioPlayer.open(Audio.network(STREAM_URL + t.id));

        /*
        if (current != null) {
          await assetsAudioPlayer.open(
            //Audio.network("http://192.168.0.105:3000/api/track/"+ (current?.id as String))
        );
        }
        */

      } catch (e) {}
    } else if (Platform.isWindows) {}
  }

  void skip_prev() async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      assetsAudioPlayer.stop();
      try {
        Track t = await getPrevTrack();
        current = t;
        await assetsAudioPlayer.open(Audio.network(STREAM_URL + t.id));
      } catch (e) {}
    } else if (Platform.isWindows) {}
  }
}
