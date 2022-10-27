import 'dart:collection';
import 'dart:math';
import 'dart:isolate';
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_music_app/AppDatabase.dart';
import 'package:flutter_music_app/Settings.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as path_lib;

import 'package:assets_audio_player/assets_audio_player.dart' hide Playlist;
import 'package:android_path_provider/android_path_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dart_vlc/dart_vlc.dart' as VLC hide Playlist;

import 'Track.dart';

import 'AppDatabase.dart';
import 'API.dart';
import 'Playlist.dart';

import 'Playlist.dart';
import 'MainRoute.dart';
import 'FileUtil.dart';
import 'Util.dart';

enum PlayContext { all, playlist }

enum SortOrder {
  name,
  name_desc,
  artist,
  artist_desc,
  added,
  added_desc,
  playlist,
  playlist_desc
}

enum LoopMode { none, one, all }

class Player {
  static int maxShufflePlayed = 16;

  Player(MainRouteState crt) {
    this.crt = crt;
  }

  late MainRouteState crt;

  AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();
  VLC.Player? vlcPlayer;

  Playlist? currentPlaylist;
  PlayContext _playContext = PlayContext.all;
  SortOrder _sortOrder = SortOrder.playlist;

  Track? current;
  int currentIndex = 0;
  Duration currentDuration = new Duration();

  List<Track> _tracks = [];
  List<Track> _shuffleTracks = [];

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
    if (Platform.isLinux || Platform.isWindows) {
      vlcPlayer = VLC.Player(id: 69420, commandlineArguments: ['--no-video']);
    }

    currentPlaylist = playlist;

    if (Platform.isAndroid || Platform.isIOS) {
      // Audio Assets initialization
      assetsAudioPlayer.showNotification = true;
      assetsAudioPlayer.playerState.listen((event) {
        if (event == PlayerState.pause) {
          print("Player: music pause");
          crt.playerPausedCallback();
        } else if (event == PlayerState.play) {
          print("Player: music play");
          crt.playerPlayCallback();
        }
      });

      assetsAudioPlayer.currentPosition.listen((event) {
        currentDuration = event;
        Duration? trackDuration =
            assetsAudioPlayer.current.value?.audio.duration;
        double fraction = event / trackDuration!;
        crt.updateSeekBar(fraction);
      });

      assetsAudioPlayer.playlistAudioFinished.listen((Playing playing) {
        if (assetsAudioPlayer.playerState.value == PlayerState.play) {
          print("Player: music finished play");
        } else if (assetsAudioPlayer.playerState.value == PlayerState.pause) {
        } else if (assetsAudioPlayer.playerState.value == PlayerState.stop) {
          print("Player: music finished stopped");
          if (!ignoreStop) {
            skipNext();
          }
        }
        //if (assetsAudioPlayer.isPlaying.value) {
        //  skip_next();
        //}
      });
    } else if (Platform.isWindows || Platform.isLinux) {
      // VLC initialization

      vlcPlayer?.playbackStream.listen((VLC.PlaybackState state) {
        //state.isPlaying;
        //state.isSeekable;
        //state.isCompleted;
        if (state.isCompleted) {
          print("VLCPlayer: music finished play");
          if (!ignoreStop) {
            skipNext();
          }
        } else if (state.isPlaying) {
          print("VLCPlayer: music playing");
        }
      });

      vlcPlayer?.currentStream.listen((VLC.CurrentState state) {
        //state.index;
        //state.media;
        //state.medias;
        //state.isPlaylist;
        //if (state.media) {
        //}
      });

      vlcPlayer?.positionStream.listen((position) {
        //print(position.duration?.inMilliseconds.toString());
        Duration? trackDuration = position.duration;
        double fraction = position.position! / trackDuration!;
        crt.updateSeekBar(fraction);
      });
    }

    _permissionReady = false;
    _isLoading = true;

    FileUtil.preparePermissions();
  }
  /*
  Future<Null> _prepare() async {
    _permissionReady = await FileUtil.checkPermission();
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
  */

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
          print("oid " + currentPlaylist!.id);
          print("oid " + c.oid.toString());

          Track next = await AppDatabase.fetchNextTrack(
              c.oid as String, crt.getSortOrder());
          print("" + next.name);
          return next;
        } else {
          addToShuffleHistory(c);
          print("Player.getNextTrack: shuffle len " +
              _shufflePlayed.length.toString());

          Track next = await AppDatabase.fetchNextTrackShuffle(
              c.oid as String, _shufflePlayed);
          print("" + next.name);
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
          print("" + next.name);
          return next;
        }
      } else {
        if (isShuffle) {
          var t = _shuffleTracks[currentIndex];
          currentIndex = currentIndex + 1;
          if (currentIndex > _shuffleTracks.length) {
            currentIndex = 0;
            _shuffleTracks = _tracks;
            _shuffleTracks.shuffle();
          }
          return t;
        } else {
          print("" + currentIndex.toString() + " " + _tracks.length.toString());
          if (currentIndex == _tracks.length) {
            currentIndex = 0;
          } else {
            currentIndex = currentIndex + 1;
          }
          return _tracks[currentIndex];
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
          print("" + next.name);
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
        if (isShuffle) {
          var t = _shuffleTracks[currentIndex];
          currentIndex = currentIndex + 1;
          if (currentIndex > _shuffleTracks.length) {
            currentIndex = 0;
            _shuffleTracks = _tracks;
            _shuffleTracks.shuffle();
          }
          return t;
        } else {
          print("" + currentIndex.toString() + " " + _tracks.length.toString());
          if (currentIndex == 0) {
            currentIndex = _tracks.length - 1;
          } else {
            currentIndex = currentIndex - 1;
          }
          return _tracks[currentIndex];
        }
      }
    }
    throw Exception();
  }

  void playOrPause() {
    if (Platform.isAndroid || Platform.isIOS) {
      assetsAudioPlayer.playOrPause();
    } else if (Platform.isWindows || Platform.isLinux) {
      vlcPlayer?.playOrPause();
    }
  }

  Future<String> prepTrackDir(Track track) async {
    String trackLibDir = (await FileUtil.getAppMusicDir(""))!;

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
    _permissionReady = await FileUtil.preparePermissions();
    if (_permissionReady) {
      var saveDir = await prepTrackDir(track);

      var filePath = path_lib.join(saveDir, path_lib.basename(track.file_path));
      print("downloading to: " + filePath);

      var checkDuplicate = File(filePath);

      if (checkDuplicate.existsSync()) {
        //do nothing
      } else {
        //download
        var url = Settings.urlHTTP + "/api/track/" + track.id;
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

  void play(Track t, Playlist? p, int index, List<Track> track, int trackCount,
      SortOrder sortOrder) async {
    if (p!.id != currentPlaylist?.id) {
      _shufflePlayed = new Queue();
    }
    current = t;
    currentPlaylist = p;
    currentIndex = index;
    _tracks = track;
    _trackCount = trackCount;
    _sortOrder = sortOrder;

    print("Player.play: " + t.name + ", " + t.oid.toString());

    if (Platform.isAndroid) {
      _permissionReady = await FileUtil.checkPermission();
      if (_permissionReady) {
        //var saveDir = await prepTrackDir(t);
        String trackLibDir = (await FileUtil.getAppMusicDir(""))!;

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
    } else if (Platform.isWindows || Platform.isLinux) {
      playStream(t);
    }
  }

  void playStream(Track track) async {
    current = track;

    if (Platform.isAndroid) {
      try {
        //assetsAudioPlayer.stop();
        await assetsAudioPlayer
            .open(Audio.network(Settings.urlHTTP + "/api/track/" + track.id));

        print('Player.playStream: playing!');
      } catch (t) {
        print('Player.playStream: could not play!');
      }
    } else if (Platform.isIOS) {
    } else if (Platform.isWindows || Platform.isWindows) {
      final media =
          VLC.Media.network(Settings.urlHTTP + "/api/track/" + track.id);
      vlcPlayer?.open(media, autoStart: true);
    }
  }

  void playFile(Track track) async {
    current = track;

    if (Platform.isAndroid) {
      try {
        var externalStorageDirPath =
            await AndroidPathProvider.musicPath + "/Whale Music";

        final file = File('${externalStorageDirPath}/${track.file_path}');
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
    try {
      Track t = await getNextTrack();

      print('Player.skip_next: ' + t.file_path);
      crt.setCurrentTrack(t);
      play(t, currentPlaylist, currentIndex, _tracks, _trackCount, _sortOrder);
    } catch (e) {
      print('Player.skip_next: error' + e.toString());
    }
  }

  void skipPrev() async {
    print('Player.skipPrev:');
    try {
      Track t = await getPrevTrack();
      crt.setCurrentTrack(t);
      play(t, currentPlaylist, currentIndex, _tracks, _trackCount, _sortOrder);
    } catch (e) {}
  }

  void setShuffleMode(bool shuffleMode) {
    isShuffle = shuffleMode;

    if (currentPlaylist!.id == "#ALL#" || currentPlaylist?.id == "#FAV#") {
    } else {
      _shuffleTracks = _tracks;
      _shuffleTracks.shuffle();
    }
  }

  void seek(double value) {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      Duration? d = assetsAudioPlayer.current.value?.audio.duration;
      Duration newD = d! * value;
      assetsAudioPlayer.seek(newD);
      //print(d);
    } else if (Platform.isWindows) {}
  }

  void setLoopMode(LoopMode loopMode) {
    this.loopMode = loopMode;
  }

  SortOrder getCurrentSortOrder() {
    return _sortOrder;
  }

  List<Track> getTracks() {
    return _tracks;
  }

  void setTracks(List<Track> sortedTracks) {
    _tracks = sortedTracks;
  }
}
