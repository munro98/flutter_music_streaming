import 'dart:collection';
import 'dart:math';
import 'dart:isolate';
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_music_app/AppDatabase.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as path_lib;

import 'package:assets_audio_player/assets_audio_player.dart' hide Playlist;
import 'package:android_path_provider/android_path_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dart_vlc/dart_vlc.dart' hide Playlist;

import 'Track.dart';

import 'AppDatabase.dart';
import 'API.dart';
import 'Playlist.dart';

import 'Playlist.dart';
import 'CategoryRoute.dart';

enum PlayContext { all, playlist }

enum LoopMode { none, one, all }

const String STREAM_URL = "http://192.168.0.105:3000/api/track/";

class Player {
  static int maxShufflePlayed = 16;

  Player(CategoryRouteState crt) {
    this.crt = crt;
  }

  late CategoryRouteState crt;

  AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();

  Playlist? currentPlaylist;
  Track? current;
  int current_ind = 0;

  List<Track> _tracks = [];
  List<Track> shuffle_tracks = [];

  Queue<String> _shufflePlayed = new Queue();
  int _trackCount = 0;

  ReceivePort _port = ReceivePort();
  late String _localPath;

  LoopMode loopMode = LoopMode.none;
  bool isShuffle = false;

  late bool _permissionReady;
  late bool _isLoading;

  bool ignoreStop = false;

  void init(Playlist playlist) {
    currentPlaylist = playlist;

    assetsAudioPlayer.playlistAudioFinished.listen((Playing playing) {
      if (assetsAudioPlayer.playerState.value == PlayerState.play) {
        print("Player: music finished play");
      } else if (assetsAudioPlayer.playerState.value == PlayerState.pause) {
        print("Player: music finished pause");
      } else if (assetsAudioPlayer.playerState.value == PlayerState.stop) {
        print("Player: music finished stopped");
        if (!ignoreStop) {
          skipNext();
        }
      }

      _permissionReady = false;
      _isLoading = true;
      _prepare();
      //assetsAudioPlayer.

      //if (assetsAudioPlayer.isPlaying.value) {
      //  skip_next();
      //}
    });
  }

  Future<Null> _prepare() async {
    _permissionReady = await _checkPermission();
    if (_permissionReady) {
      await _prepareSaveDir();
    }

    _isLoading = false;
  }

  Future<bool> _checkPermission() async {
    if (Platform.isIOS) return true;

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    }
    return false;
  }

  Future<String?> _findLocalPath() async {
    var externalStorageDirPath;
    if (Platform.isAndroid) {
      try {
        externalStorageDirPath =
            await AndroidPathProvider.musicPath + "/Whale Music";
      } catch (e) {
        final directory = await getExternalStorageDirectory();
        externalStorageDirPath = directory?.path;
      }
    } else if (Platform.isIOS) {
      externalStorageDirPath =
          (await getApplicationDocumentsDirectory()).absolute.path;
    }
    return externalStorageDirPath;
  }

  Future<void> _prepareSaveDir() async {
    _localPath = (await _findLocalPath())!;
    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

/*
  void loadPlaylist(Playlist playlist) async {
    if (playlist.id == "#ALL#") {

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
  */

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

  void addToShuffleHistory(Track t) {
    if (t.oid != null) {
      _shufflePlayed.addLast(t.oid!);
      while (_shufflePlayed.length > maxShufflePlayed) {
        _shufflePlayed.removeFirst();
      }
      if (_shufflePlayed.length >= _trackCount) {
        _shufflePlayed = new Queue();
      }
    }
  }

  Future<Track> getNextTrack() async {
    Track c = current as Track;
    if (current != null) {
      if (currentPlaylist == null || currentPlaylist!.id == "#ALL#") {
        if (!isShuffle) {
          print(
              "________________________________________________________________________oid " +
                  currentPlaylist!.id);
          print(
              "________________________________________________________________________oid " +
                  c.oid.toString());

          Track next = await AppDatabase.fetchNextTrack(
              c.oid as String, crt.getSortOrder());
          print("________________________________________" + next.name);
          return next;
        } else {
          addToShuffleHistory(c);
          print("Player.getNextTrack: shuffle len " +
              _shufflePlayed.length.toString());

          Track next = await AppDatabase.fetchNextTrackShuffle(
              c.oid as String, _shufflePlayed);
          print("________________________________________" + next.name);
          return next;
        }
      } else if (currentPlaylist!.id == "#FAV#") {
        if (!isShuffle) {
          Track next = await AppDatabase.fetchNextTrack(
              c.oid as String, crt.getSortOrder());
          return next;
        } else {
          addToShuffleHistory(c);
          Track next = await AppDatabase.fetchNextTrackShuffleFav(
              c.oid as String, _shufflePlayed);
          print("________________________________________" + next.name);
          return next;
        }
      } else {
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
          print(
              "#######################################################################################################################################" +
                  current_ind.toString() +
                  " " +
                  _tracks.length.toString());
          if (current_ind == _tracks.length) {
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
    Track c = current as Track;
    if (current != null) {
      if (currentPlaylist == null || currentPlaylist!.id == "#ALL#") {
        if (!isShuffle) {
          if (current != null) {
            Track next = await AppDatabase.fetchPrevTrack(
                c.oid as String, crt.getSortOrder());
            return next;
          }
        } else {
          addToShuffleHistory(c);
          Track next = await AppDatabase.fetchNextTrackShuffle(
              c.oid as String, _shufflePlayed);
          print("________________________________________" + next.name);
          return next;
        }
      } else if (currentPlaylist!.id == "#FAV#") {
        if (!isShuffle) {
          if (current != null) {
            Track next = await AppDatabase.fetchPrevTrackFav(
                c.oid as String, crt.getSortOrder());
            return next;
          }
        } else {
          addToShuffleHistory(c);
          Track next = await AppDatabase.fetchNextTrackShuffleFav(
              c.oid as String, _shufflePlayed);
          return next;
        }
      } else {
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

  void playOrPause() {
    assetsAudioPlayer.playOrPause();
  }

  Future<String> prepTrackDir(Track track) async {
    String trackLibDir = (await _findLocalPath())!;

    final dirname = path_lib.dirname(track.file_path);
    final trackDir = path_lib.join(trackLibDir, dirname);
    final savedDir = Directory(trackDir);
    bool hasExisted = await savedDir.exists();

    if (!hasExisted) {
      savedDir.create();
    }
    return trackDir;
  }

  void downloadTrack(Track track) async {
    _permissionReady = await _checkPermission();
    if (_permissionReady) {
      var saveDir = await prepTrackDir(track);

      var filePath = path_lib.join(saveDir, path_lib.basename(track.file_path));
      print("downloading to: " + filePath);

      var checkDuplicate = File(filePath);

      if (checkDuplicate.existsSync()) {
        //do nothing
      } else {
        //download
        var url = "http://192.168.0.105:3000/api/track/" + track.id;
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

  void play(Track t, Playlist? p, int index, List<Track> track,
      int trackCount) async {
    if (p!.id != currentPlaylist?.id) {
      _shufflePlayed = new Queue();
    }
    current = t;
    currentPlaylist = p;
    current_ind = index;
    _tracks = track;
    _trackCount = trackCount;

    print("Player.play: " + t.name + ", " + t.oid.toString());

    if (Platform.isAndroid) {
      _permissionReady = await _checkPermission();
      if (_permissionReady) {
        //var saveDir = await prepTrackDir(t);
        String trackLibDir = (await _findLocalPath())!;

        final dirname = path_lib.dirname(t.file_path);

        final trackDir = path_lib.join(trackLibDir, dirname);
        var filePath = path_lib.join(trackDir, path_lib.basename(t.file_path));

        print("Play.play: " + filePath);

        var checkFile = File(filePath);

        if (checkFile.existsSync()) {
          assetsAudioPlayer.open(
            Audio.file(filePath),
          );
        } else {
          playStream(t);
          downloadTrack(t); // queue for download
        }
      }
    } else if (Platform.isIOS) {
    } else if (Platform.isWindows || Platform.isMacOS) {}
  }

  void playStream(Track track) async {
    current = track;

    if (Platform.isAndroid) {
      try {
        //assetsAudioPlayer.stop();
        await assetsAudioPlayer.open(Audio.network(STREAM_URL + track.id));

        //assetsAudioPlayer.open(
        //  Audio("assets/DROELOE - Taking Flight.flac"),
        //);

        print('Player.playStream: playing!');
      } catch (t) {
        print('Player.playStream: could not play!');
      }
    } else if (Platform.isIOS) {
    } else if (Platform.isWindows) {}
  }

  void playFile(Track track) async {
    current = track;

    if (Platform.isAndroid) {
      try {
        //assetsAudioPlayer.stop();

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
      } catch (t) {
        print('Player.playFile: could not play!');
      }
    } else if (Platform.isWindows) {}
  }

  void playPause() {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      assetsAudioPlayer.playOrPause();
    } else if (Platform.isWindows) {}
  }

  void skipNext() async {
    print('Player.skipNext:');
    if (Platform.isAndroid) {
      try {
        Track t = await getNextTrack();

        print('Player.skip_next: ' + t.file_path);
        crt.setCurrentTrack(t);
        play(t, currentPlaylist, current_ind, _tracks, _trackCount);
      } catch (e) {
        print('Player.skip_next: error' + e.toString());
      }
    } else if (Platform.isIOS) {
    } else if (Platform.isWindows || Platform.isMacOS) {}
  }

  void skipPrev() async {
    print('Player.skipPrev:');
    if (Platform.isAndroid) {
      try {
        Track t = await getPrevTrack();
        crt.setCurrentTrack(t);
        play(t, currentPlaylist, current_ind, _tracks, _trackCount);
      } catch (e) {}
    } else if (Platform.isIOS) {
    } else if (Platform.isWindows || Platform.isMacOS) {}
  }

  void setShuffleMode(bool shuffleMode) {
    isShuffle = shuffleMode;
  }

  void setLoopMode(LoopMode loopMode) {
    this.loopMode = loopMode;
  }
}
