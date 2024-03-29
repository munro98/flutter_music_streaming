import 'dart:collection';
import 'dart:developer';
import 'dart:math';
import 'dart:isolate';
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path_lib;

import 'package:assets_audio_player/assets_audio_player.dart' hide Playlist;
import 'package:dart_vlc/dart_vlc.dart' as VLC hide Playlist;
import 'package:mutex/mutex.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:android_path_provider/android_path_provider.dart';

import 'DownloadManager.dart';
import 'Settings.dart';
import 'Track.dart';
import 'AppDatabase.dart';
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

enum LoopMode { none, all, one }

/* class AudioPlayerService extends Service {
  final AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();

  @override
  void onCreate() {
    super.onCreate();
    // Set up your audio player here
    // assetsAudioPlayer.open(Audio.file('path/to/audio/file.mp3'));
  }

  @override
  int onStartCommand(Intent intent, int flags, int startId) {
    // Listen for the playlistAudioFinished event
    assetsAudioPlayer.playlistAudioFinished.listen((Playing playing) {
      // Call the skipNext function when the event is triggered
      //skipNext(false);
    });

    // Start the service in the foreground and show a notification
    final Notification notification = Notification(
      title: 'Audio Player',
      text: 'Playing music',
      icon: Icons.music_note,
    );
    startForeground(1, notification);

    // Return START_STICKY to indicate that the service should be restarted if it is killed
    return START_STICKY;
  }

  @override
  void onDestroy() {
    super.onDestroy();
    // Stop listening for the playlistAudioFinished event and release the audio player
    assetsAudioPlayer.playlistAudioFinished.removeAllListeners();
    assetsAudioPlayer.dispose();
  }

  @override
  IBinder onBind(Intent intent) => null;
} */

class Player {
  static int maxShufflePlayed = 32;

  Player(MainRouteState crt) {
    this.crt = crt;
  }

  final log = Logger('Player');
  late MainRouteState crt;

  AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();
  VLC.Player? vlcPlayer;
  StreamSubscription<VLC.PlaybackState>? vlcSS;
  StreamSubscription<VLC.PositionState>? vlcPS;

  Playlist? currentPlaylist;
  //PlayContext _playContext = PlayContext.all;
  SortOrder _sortOrder = SortOrder.playlist;

  List<Track> _tracks = [];

  List<Track> _shuffleTracks = [];
  Queue<String> _shufflePlayed = new Queue();

  //ReceivePort _port = ReceivePort();

  Track? current;
  Duration currentDuration = new Duration();
  int currentIndex = 0;
  //int _trackCount = 0;

  LoopMode loopMode = LoopMode.none;
  bool isShuffle = false;
  late bool _permissionReady;
  bool ignoreStop = false;

  final skipMutex = Mutex();

  void init(Playlist playlist) {
    currentPlaylist = playlist;

    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
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
          skipNext(false);
        }
        //if (assetsAudioPlayer.isPlaying.value) {
        //  skip_next();
        //}
      });
    } else if (Platform.isWindows || Platform.isLinux) {
      vlcPlayer = VLC.Player(id: 69420, commandlineArguments: ['--no-video']);
      vlcSS = vlcPlayer?.playbackStream.listen((VLC.PlaybackState state) async {
        //state.isPlaying;
        //state.isSeekable;
        //state.isCompleted;
        if (state.isCompleted) {
          print("VLCPlayer: music finished play");

          skipNext(false);
        } else if (state.isPlaying) {
          //print("VLCPlayer: state.isPlaying");
          crt.playerPlayCallback();
        } else if (!state.isPlaying) {
          //print("VLCPlayer: !state.isPlaying");
          crt.playerPausedCallback();
        }
      });

      /* vlcPlayer?.currentStream.listen((VLC.CurrentState state) {
        //state.index;
        //state.media;
        //state.medias;
        //state.isPlaylist;
      }); */
      vlcPS = vlcPlayer?.positionStream.listen((position) {
        //print(position.duration?.inMilliseconds.toString());
        Duration? trackDuration = position.duration;
        double fraction = position.position! / trackDuration!;
        crt.updateSeekBar(fraction);
      });
    }
    FileUtil.preparePermissions();
  }

  void unInit() {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      assetsAudioPlayer.dispose();
    } else if (Platform.isWindows || Platform.isLinux) {
      vlcSS!.cancel();
      vlcPS!.cancel();
      vlcPlayer!.dispose();
    }
  }

  void addToShuffleHistory(Track t) {
    if (t.oid != null) {
      _shufflePlayed.addLast(t.oid!);
      while (_shufflePlayed.length > maxShufflePlayed) {
        _shufflePlayed.removeFirst();
      }
      if (_shufflePlayed.length >= _tracks.length) {
        _shufflePlayed = new Queue();
      }
    }
  }

  Future<Track?> getNextTrack(bool userInvoked) async {
    Track c = current as Track;

    if (loopMode == LoopMode.one) {
      if (userInvoked) {
        this.loopMode = LoopMode.all;
        crt.setLoopModeCallback(this.loopMode);
      } else {
        return current;
      }
    }
    if (!isShuffle) {
      print("" + currentIndex.toString() + " " + _tracks.length.toString());
      if (currentIndex >= _tracks.length) {
        currentIndex = 0;
      } else {
        currentIndex = currentIndex + 1;
      }
      print("NEW INDEX " +
          currentIndex.toString() +
          " " +
          _tracks[currentIndex].name);
      return _tracks[currentIndex];
    } else {
      if (currentPlaylist!.id == "#ALL#") {
        addToShuffleHistory(c);
        Track next = await AppDatabase.fetchNextTrackShuffle(
            c.oid as String, _shufflePlayed);
        print("" + next.name);
        return next;
      } else if (currentPlaylist!.id == "#FAV#") {
        addToShuffleHistory(c);
        Track next = await AppDatabase.fetchNextTrackShuffleFav(
            c.oid as String, _shufflePlayed);
        return next;
      } else {
        if (currentIndex >= _tracks.length) {
          currentIndex = 0;
        } else {
          currentIndex = currentIndex + 1;
        }
        return _tracks[currentIndex];
      }
    }
  }

  Future<Track?> getPrevTrack(bool userInvoked) async {
    Track c = current as Track;
    if (loopMode == LoopMode.one) {
      if (userInvoked) {
        this.loopMode = LoopMode.all;
        crt.setLoopModeCallback(this.loopMode);
      } else {
        return current;
      }
    }
    if (!isShuffle) {
      print("" + currentIndex.toString() + " " + _tracks.length.toString());
      if (currentIndex <= 0) {
        currentIndex = _tracks.length - 1;
      } else {
        currentIndex = currentIndex - 1;
      }
      return _tracks[currentIndex];
    } else {
      if (currentPlaylist!.id == "#ALL#") {
        addToShuffleHistory(c);
        Track next = await AppDatabase.fetchNextTrackShuffle(
            c.oid as String, _shufflePlayed);
        print("" + next.name);
        return next;
      } else if (currentPlaylist!.id == "#FAV#") {
        addToShuffleHistory(c);
        Track next = await AppDatabase.fetchNextTrackShuffleFav(
            c.oid as String, _shufflePlayed);
        return next;
      } else {
        if (currentIndex <= 0) {
          currentIndex = _tracks.length - 1;
        } else {
          currentIndex = currentIndex - 1;
        }
        return _tracks[currentIndex];
      }
    }
  }

  void playOrPause() {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      assetsAudioPlayer.playOrPause();
    } else if (Platform.isWindows || Platform.isLinux) {
      vlcPlayer?.playOrPause();
    }
  }

  void play(Track t, Playlist? p, int index, List<Track> track,
      SortOrder sortOrder) async {
    if (p!.id != currentPlaylist?.id) {
      _shufflePlayed = new Queue();
    }
    current = t;
    currentPlaylist = p;
    currentIndex = index;
    _tracks = track;
    //_trackCount = trackCount;
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
          DownloadManager.downloadTrack(t); // queue for download
        }
      }
    } else if (Platform.isIOS) {
    } else if (Platform.isWindows || Platform.isLinux) {
      playStream(t);
    }
  }

  void playStream(Track track) async {
    current = track;

    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
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
      // TODO
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
        log.severe('Player.playFile: could not play!', t);
      }
    } else if (Platform.isWindows) {}
  }

  void playPause() {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      assetsAudioPlayer.playOrPause();
    } else if (Platform.isWindows) {}
  }

  Future<void> skipNext(bool userInvoked) async {
    print('Player.skipNext:');
    try {
      Track? t = await getNextTrack(userInvoked);
      if (t != null) {
        print('Player.skip_next: ' + t.file_path);
        crt.setCurrentTrack(t);
        if (t.playlist_index != null) crt.jumpTo(t.playlist_index);
        play(t, currentPlaylist, currentIndex, _tracks, _sortOrder);
      }
    } catch (e) {
      print('Player.skip_next: error' + e.toString());
    }
  }

  void skipPrev(bool userInvoked) async {
    print('Player.skipPrev:');
    Track? t = await getPrevTrack(userInvoked);
    try {
      if (t != null) {
        crt.setCurrentTrack(t);
        play(t, currentPlaylist, currentIndex, _tracks, _sortOrder);
      }
    } catch (e) {
      print('Player.skip_prev: error' + e.toString());
    }
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
      if (assetsAudioPlayer.current.hasValue) {
        Duration? d = assetsAudioPlayer.current.value?.audio.duration;
        Duration newD = d! * value;
        assetsAudioPlayer.seek(newD);
      }
    } else if (Platform.isLinux || Platform.isWindows) {
      Duration? d = vlcPlayer?.position.duration;
      Duration newD = d! * value;
      vlcPlayer?.seek(newD);
      //print("new" + newD.toString());
    }
  }

  void vol(double value) {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      assetsAudioPlayer.setVolume(value);
    } else if (Platform.isLinux || Platform.isWindows) {
      vlcPlayer?.setVolume(value);
    }
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
