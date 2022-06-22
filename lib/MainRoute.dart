import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';

import 'package:assets_audio_player/assets_audio_player.dart'
    hide Playlist, LoopMode;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:android_path_provider/android_path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'dart:isolate';
import 'dart:ui';

import 'Player.dart';
import 'Track.dart';
import 'AppDatabase.dart';
import 'API.dart';
import 'Playlist.dart';
import 'SeekBar.dart';
import 'Settings.dart';

/*
todo

dragable seekbar
shuffle playing for playlists
fix added_date sort order

add windows support with vlc_player for music and 
sqflite_common_ffi for database

add settings menu and able to edit server ip

mini notification player widget
https://pub.dev/packages/flutter_local_notifications

add album sortOrder

grey out tracks unavailable when offline
looping
detect when track can't be played due to end of playlist/missing connection to server/other reason

able to enable/disable songs in library and playlists
drag and drop songs into playlist
delete (unchecked/ least played songs)

## stretch goal ##
sync(play count/ last date played)
remote control for other devices(websockets)
artist view
album view
*/

ReceivePort _port = ReceivePort();

class Choice {
  const Choice(String this.title, IconData this.icon);

  final String title;
  final IconData icon;
}

const List<Choice> choices = const <Choice>[
  const Choice('Refresh', Icons.directions_car),
  const Choice('Download Playlist Data', Icons.directions_boat),
  const Choice('Download Tracks in Playlist', Icons.directions_bus),
  const Choice('Open Settings', Icons.directions_bus),
];

const List<Color> loopModeColors = const <Color>[
  Colors.black,
  Colors.blue,
  Colors.yellow
];

class MainRoute extends StatefulWidget {
  const MainRoute();

  @override
  MainRouteState createState() => MainRouteState();
}

class MainRouteState extends State<MainRoute> {
  //String? localFilePath;

  final Playlist allPlayList = new Playlist("All Music", "#ALL#");
  final Playlist favouritePlayList = new Playlist("Favourites", "#FAV#");

  List<Track> _tracks = <Track>[];
  late Playlist _currentPlayList = allPlayList;
  late Playlist _playingPlayList = allPlayList;
  Choice _selectedChoice = choices[0];
  SortOrder _sortOrder = SortOrder.playlist;

  PlayContext _vs = PlayContext.all;
  List<Playlist> _playlists = [];

  late Player _player = Player(this);
  Track? current;

  final int _pageSize = 128;
  final int _maxPagesSize = 16;

  Map<int, bool> _pageMapIsFetching = Map<int, bool>();
  Map<int, List<Track>> _pageMap = Map<int, List<Track>>();
  int _pageMapCount = 0;
  int _trackCount = 0;

  String _currentTrack = "";
  bool _shuffleMode = false;
  LoopMode _loopMode = LoopMode.none;
  bool _isConnected = false;

  GlobalKey<SeekBarState> _seekKey = GlobalKey();
  GlobalKey<ScaffoldState> scaffKey = new GlobalKey<ScaffoldState>();

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      setState(() {});
    });

    FlutterDownloader.registerCallback(downloadCallback);
    AppDatabase.openConnection()
        .then((value) => loadPlaylist(_currentPlayList, _sortOrder));

    _player.init(_currentPlayList);

    fetchPlaylists();

    _player.assetsAudioPlayer.current.listen((playing) {
      //final path = playing?.audio.path;
      final songDuration = playing?.audio.duration;
      _seekKey.currentState?.setDurationValue(songDuration!);
      //_seekKey.currentState?.reset();

      _seekKey.currentState?.setProgressValue(0.0);

      print("song duration " + songDuration.toString());
    });

    print(" initState" + _tracks.length.toString());
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');

    super.dispose();
  }

  void playerPausedCallback() {
    _seekKey.currentState?.stop();
  }

  void playerPlayCallback() {
    _seekKey.currentState?.resume();
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  fetchPlaylists() async {
    //print(" fetchPlaylists" + _playlists.length.toString());
    try {
      //List<Playlist> playlists = await Api.fetchPlaylists();
      List<Playlist> playlists = await PlaylistManager.fetchPlaylists();
      playlists.insert(0, allPlayList);
      playlists.insert(1, favouritePlayList);

      setState(() {
        _playlists = playlists;
        _vs = PlayContext.playlist;
      });
    } catch (e) {
      // TODO: make this work
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Hi, I am a snack bar!"),
      ));

      print("MainRoute.fetchPlaylists error: " + e.toString());
    }
  }

  // TODO: figure when to remove data
  Future<void> _fetchPage(int pageKey, String id, SortOrder sortOrder) async {
    try {
      if (_pageMapIsFetching.containsKey(pageKey)) return;

      _pageMapIsFetching[pageKey] = true;

      // Remove old pages outside of the scroll viewable area
      /*
      // TODO: figure out a better way to do this
      if (_pageMap.length > _maxPagesSize) {
        for (int i = 0; i < pageKey - 10; i++) {
          if (_pageMap.containsKey(i)) {
            _pageMap.remove(i);
          }
        }
        for (int i = pageKey+10; i > pageKey; i--) {
          if (_pageMap.containsKey(i)) {
            _pageMap.remove(i);
          }
        }
        
      }
      */

      // fill new pages
      List<Track> data;

      if (_currentPlayList.id == "#FAV#") {
        data =
            await AppDatabase.fetchTracksPageFav(_pageSize, pageKey, sortOrder);
      } else {
        data = await AppDatabase.fetchTracksPage(_pageSize, pageKey, sortOrder);
      }

      print("main._fetchPage: GOT PAGE DATA: " + pageKey.toString());

      int count = 0;
      _pageMap.forEach((k, v) => {count += v.length});
      count += data.length;

      _pageMapIsFetching.remove(pageKey);

      this.setState(() {
        _pageMap[pageKey] = data;
        _pageMapCount = count;
      });
    } catch (e) {
      _pageMapIsFetching.remove(pageKey);
    }
  }

  bool _hasTrack(int index) {
    int page = (index ~/ _pageSize).toInt();
    int pIndex = index % _pageSize;

    if (!_pageMap.containsKey(page)) return false;
    if (pIndex >= _pageMap[page]!.length) return false;

    return true;
  }

  Track _fetchTrack(int index) {
    int page = (index ~/ _pageSize).toInt();
    int pIndex = index % _pageSize;
    //print("main._fetchTrack: " + page.toString() + " " + _pageMap.length.toString());
    return _pageMap[page]![pIndex];
  }

  void _select(Choice choice) {
    setState(() {
      _selectedChoice = choice;
    });
  }

  // update local database with server database
  void refresh() async {
    // TODO: pagingate server API requests
    final tracks = await Api.fetchTracks("track", "");

    for (int i = 0; i < tracks.length; i++) {
      AppDatabase.insertTrack(tracks[i]);
    }
  }

  void refreshPlaylists() async {
    //List<Playlist> playlists = await Api.fetchPlaylists();
    List<Playlist> playlists = await PlaylistManager.fetchPlaylists();

    playlists.insert(0, allPlayList);
    playlists.insert(1, favouritePlayList);

    setState(() {
      _vs = PlayContext.playlist;
      _playlists = playlists;
    });
  }

  void onAction(Choice choice, BuildContext ctx) {
    if (choice.title == 'Refresh') {
      print("MainRoute.onAction: " + "refreshPlaylists()");
      refreshPlaylists();
    } else if (choice.title == 'Download Playlist Data') {
      print("MainRoute.onAction: " + "PlaylistManager.downloadPlaylists();");
      PlaylistManager.downloadPlaylists();
    } else if (choice.title == "Download Tracks in Playlist") {
      if (_vs == PlayContext.playlist) {
        print("MainRoute.onAction: " +
            "PlaylistManager.downloadTracksInPlaylists(_currentPlayList);");
        PlaylistManager.downloadTracksInPlaylists(_currentPlayList);
      }
    } else if (choice.title == "Open Settings") {
      print("MainRoute.onAction: Open Settings");
      Navigator.push(
        ctx,
        MaterialPageRoute(builder: (c) => const SettingsRoute()),
      );
      Navigator.push(
        ctx,
        MaterialPageRoute(builder: (c) => const SettingsRoute()),
      );
    }
  }

  void loadPlaylist(Playlist playlist, SortOrder sortOrder) async {
    // coming from another playlist to one currently playing
    if (playlist.id != _currentPlayList.id &&
        playlist.id == _player.currentPlaylist?.id) {
      sortOrder = _player.getCurrentSortOrder();
    }

    if (playlist.id == "#ALL#") {
      int trackCount = await AppDatabase.fetchTracksCount();
      print("main.loadPlaylist: " + trackCount.toString());
      _fetchPage(0, playlist.id, sortOrder);

      setState(() {
        _sortOrder = sortOrder;
        _currentPlayList = playlist;
        _trackCount = trackCount;
        _vs = PlayContext.all;
      });

      _pageMap.forEach((k, v) => {_fetchPage(k, playlist.id, sortOrder)});
    } else if (playlist.id == "#FAV#") {
      int trackCount = await AppDatabase.fetchTracksCountFav();
      print("main.loadPlaylist: " + trackCount.toString());
      _fetchPage(0, playlist.id, sortOrder);

      setState(() {
        _sortOrder = sortOrder;
        _currentPlayList = playlist;
        _trackCount = trackCount;
        _vs = PlayContext.all;
      });
      _pageMap.forEach((k, v) => {_fetchPage(k, playlist.id, sortOrder)});
    } else {
      // Switching to actively playing playlist
      if (playlist.id == _currentPlayList.id &&
          playlist.id == _player.currentPlaylist!.id) {
        List<TrackPair> trackP = [];
        List<Track> playerTracks = _player.getTracks();

        for (int i = 0; i < playerTracks.length; i++) {
          trackP.add(new TrackPair(i, playerTracks[i]));
        }

        if (sortOrder == SortOrder.name) {
          trackP.sort(((l, r) => Track.nameCompare(l.track, r.track)));
        } else if (sortOrder == SortOrder.name_desc) {
          trackP.sort(((l, r) => Track.nameCompareReverse(l.track, r.track)));
        } else if (sortOrder == SortOrder.artist) {
          trackP.sort(((l, r) => Track.artistCompare(l.track, r.track)));
        } else if (sortOrder == SortOrder.artist_desc) {
          trackP.sort(((l, r) => Track.artistCompareReverse(l.track, r.track)));
        } else if (sortOrder == SortOrder.added) {
          trackP.sort(((l, r) => Track.addedCompare(l.track, r.track)));
        } else if (sortOrder == SortOrder.added_desc) {
          trackP.sort(((l, r) => Track.addedCompareReverse(l.track, r.track)));
        } else if (sortOrder == SortOrder.playlist) {
          trackP.sort(((l, r) => Track.playlistCompare(l.track, r.track)));
        } else if (sortOrder == SortOrder.playlist_desc) {
          trackP
              .sort(((l, r) => Track.playlistCompareReverse(l.track, r.track)));
        }
        /* move the player index after reordering the playlist
        a 0 <- index
        b 1
        c 2
        -> after sorting
        c 2
        b 1
        a 0 <- index
        */
        List<Track> sortedTracks = [];
        int pIndex = _player.currentIndex;
        int newPIndex = -1;
        for (int i = 0; i < trackP.length; i++) {
          sortedTracks.add(trackP[i].track);
          if (trackP[i].index == pIndex) {
            newPIndex = i;
          }
        }
        _player.currentIndex = newPIndex;

        _player.setTracks(sortedTracks);

        setState(() {
          _sortOrder = sortOrder;
          _currentPlayList = playlist;
          _vs = PlayContext.playlist;
          _tracks = sortedTracks;
        });
      } else {
        final tracksids =
            await PlaylistManager.fetchPlaylistsTracks(playlist.id);
        List<Track> trackP = await AppDatabase.fetchPlaylistTracks(tracksids);

        if (sortOrder == SortOrder.name) {
          trackP.sort(((l, r) => Track.nameCompare(l, r)));
        } else if (sortOrder == SortOrder.name_desc) {
          trackP.sort(((l, r) => Track.nameCompareReverse(l, r)));
        } else if (sortOrder == SortOrder.artist) {
          trackP.sort(((l, r) => Track.artistCompare(l, r)));
        } else if (sortOrder == SortOrder.artist_desc) {
          trackP.sort(((l, r) => Track.artistCompareReverse(l, r)));
        } else if (sortOrder == SortOrder.added) {
          trackP.sort(((l, r) => Track.addedCompare(l, r)));
        } else if (sortOrder == SortOrder.added_desc) {
          trackP.sort(((l, r) => Track.addedCompareReverse(l, r)));
        } else if (sortOrder == SortOrder.playlist) {
          trackP.sort(((l, r) => Track.playlistCompare(l, r)));
        } else if (sortOrder == SortOrder.playlist_desc) {
          trackP.sort(((l, r) => Track.playlistCompareReverse(l, r)));
        }

        setState(() {
          _sortOrder = sortOrder;
          _currentPlayList = playlist;
          _vs = PlayContext.playlist;
          _tracks = trackP;
        });
      }
    }
  }

  @override
  Widget build(BuildContext rootContext) {
    return new DefaultTabController(
        length: 3,
        child: new Scaffold(
            key: scaffKey,
            drawer: new Drawer(

                //child: new Padding(
                //    padding: new EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                child: Container(
                    child: new ListView.builder(
              //padding: new EdgeInsets.all(8.0),
              itemExtent: 40.0,
              itemCount: _playlists.length,
              itemBuilder: (BuildContext context, int index) {
                return new PlaylistButton(_playlists[index], this);
              },
            ))),
            appBar: new AppBar(
                title: Text(_currentPlayList.name),
                bottom: new PreferredSize(
                  preferredSize: const Size.fromHeight(48.0),
                  child: new Theme(
                    data: Theme.of(rootContext)
                        .copyWith(accentColor: Colors.white),
                    child: new Container(
                      height: 48.0,
                      alignment: Alignment.center,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          new Expanded(
                              child: InkWell(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Title'),
                                _sortOrder == SortOrder.name ||
                                        _sortOrder == SortOrder.name_desc
                                    ? _sortOrder == SortOrder.name
                                        ? Icon(Icons.arrow_drop_down)
                                        : Icon(Icons.arrow_drop_up)
                                    : Container()
                              ],
                            ),
                            onTap: () {
                              if (_sortOrder == SortOrder.name) {
                                loadPlaylist(
                                    _currentPlayList, SortOrder.name_desc);
                              } else {
                                loadPlaylist(_currentPlayList, SortOrder.name);
                              }
                            },
                          )),
                          new Expanded(
                              child: InkWell(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Artist'),
                                  _sortOrder == SortOrder.artist ||
                                          _sortOrder == SortOrder.artist_desc
                                      ? _sortOrder == SortOrder.artist
                                          ? Icon(Icons.arrow_drop_down)
                                          : Icon(Icons.arrow_drop_up)
                                      : Container()
                                ]),
                            onTap: () {
                              if (_sortOrder == SortOrder.artist) {
                                loadPlaylist(
                                    _currentPlayList, SortOrder.artist_desc);
                              } else {
                                loadPlaylist(
                                    _currentPlayList, SortOrder.artist);
                              }
                            },
                          )),
                          new Expanded(
                              child: InkWell(
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('Date'),
                                        _sortOrder == SortOrder.added ||
                                                _sortOrder ==
                                                    SortOrder.added_desc
                                            ? _sortOrder == SortOrder.added
                                                ? Icon(Icons.arrow_drop_down)
                                                : Icon(Icons.arrow_drop_up)
                                            : Container()
                                      ]),
                                  onTap: () {
                                    if (_sortOrder == SortOrder.added) {
                                      loadPlaylist(_currentPlayList,
                                          SortOrder.added_desc);
                                    } else {
                                      loadPlaylist(
                                          _currentPlayList, SortOrder.added);
                                    }
                                  })),
                          new Expanded(
                              child: InkWell(
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('Playlist'),
                                        _sortOrder == SortOrder.playlist ||
                                                _sortOrder ==
                                                    SortOrder.playlist_desc
                                            ? _sortOrder == SortOrder.playlist
                                                ? Icon(Icons.arrow_drop_down)
                                                : Icon(Icons.arrow_drop_up)
                                            : Container()
                                      ]),
                                  onTap: () {
                                    if (_sortOrder == SortOrder.playlist) {
                                      loadPlaylist(_currentPlayList,
                                          SortOrder.playlist_desc);
                                    } else {
                                      loadPlaylist(
                                          _currentPlayList, SortOrder.playlist);
                                    }
                                  })),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: <Widget>[
                  new IconButton(
                    icon: new Icon(Icons.refresh),
                    onPressed: () async {
                      refresh();
                    },
                  ),
                  new PopupMenuButton<Choice>(
                    onSelected: _select,
                    itemBuilder: (BuildContext context) {
                      return choices.map((Choice choice) {
                        return new PopupMenuItem<Choice>(
                          value: choice,
                          child: new Text(choice.title),
                          onTap: () async {
                            onAction(choice, context);
                          },
                        );
                      }).toList();
                    },
                  )
                ]),
            bottomNavigationBar: new Container(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SeekBar(this, key: _seekKey),
                      Padding(
                          padding:
                              const EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 6.0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                new IconButton(
                                  icon: new Icon(Icons.shuffle,
                                      color: _shuffleMode
                                          ? Colors.blue[400]
                                          : Colors.black),
                                  onPressed: () {
                                    this.setState(() {
                                      _shuffleMode = !_shuffleMode;
                                    });
                                    _player.setShuffleMode(_shuffleMode);
                                    HapticFeedback.lightImpact();
                                    print(
                                        "shuffle: " + _shuffleMode.toString());
                                  },
                                ),
                                new IconButton(
                                  iconSize: 40,
                                  icon: new Icon(Icons.skip_previous),
                                  onPressed: () {
                                    _player.skipPrev();
                                    HapticFeedback.lightImpact();
                                  },
                                ),
                                new IconButton(
                                  iconSize: 60,
                                  icon: new Icon(Icons.play_arrow),
                                  onPressed: () {
                                    _player.playOrPause();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text('Yay! A SnackBar!'),
                                    ));
                                    HapticFeedback.lightImpact();
                                  },
                                ),
                                new IconButton(
                                  iconSize: 40,
                                  icon: new Icon(Icons.skip_next),
                                  onPressed: () {
                                    _player.skipNext();
                                    HapticFeedback.lightImpact();
                                  },
                                ),
                                new IconButton(
                                  icon: new Icon(Icons.loop,
                                      color: loopModeColors[_loopMode.index]),
                                  onPressed: () {
                                    this.setState(() {
                                      _loopMode = LoopMode
                                          .values[(_loopMode.index + 1) % 3];
                                    });
                                    _player.setLoopMode(_loopMode);
                                    HapticFeedback.lightImpact();
                                    print("loopmode: " + _loopMode.toString());
                                  },
                                ),
                              ]))
                    ]),
                decoration: new BoxDecoration(
                  color: Colors.grey[400],
                )) //Text("Player here", style: new TextStyle(fontSize: 16),)
            ,
            body: _vs == PlayContext.playlist
                ? ScrollablePositionedList.builder(
                    itemCount: _tracks.length,
                    itemBuilder: (BuildContext context, int index) {
                      return new TrackItem(_tracks[index], index, this);
                    },
                  )
                : NotificationListener<ScrollUpdateNotification>(
                    onNotification: (notification) {
                      //_onScroll(notification);
                      //How many pixels scrolled from pervious frame
                      //print(notification.scrollDelta);

                      //List scroll position
                      //print(notification.metrics.pixels);
                      return true;
                    },
                    child: ScrollablePositionedList.builder(
                        itemScrollController: itemScrollController,
                        itemPositionsListener: itemPositionsListener,
                        itemCount: _trackCount,
                        itemBuilder: (context, index) {
                          if (_hasTrack(index)) {
                            return new TrackItem(
                                _fetchTrack(index), index, this);
                          } else {
                            _fetchPage((index ~/ _pageSize).toInt(),
                                _currentPlayList.id, _sortOrder);
                            return Center(child: CircularProgressIndicator());
                          }
                        }),
                  )));
  }

  void play(Track l, Playlist currentPlayList, index, List<Track> tracks) {
    _player.play(l, currentPlayList, index, _tracks, _trackCount, _sortOrder);

    //_seekKey.currentState?.reset();
    Duration d = _player.assetsAudioPlayer.currentPosition.value;

    //_seekKey.currentState?.setProgressValue(0.0);
    //_seekKey.currentState?.reset();
    //_seekKey.currentState?.setRepeat(d);

    this.setState(() {
      this._currentTrack = l.oid!;
      this._playingPlayList = currentPlayList;
    });
  }

  void setCurrentTrack(Track t) {
    this.setState(() {
      this._currentTrack = t.oid!;
    });
  }

  SortOrder getSortOrder() {
    return this._sortOrder;
  }
}

/// Helper class that makes the relationship between
/// an item index and its BuildContext
///
class ItemContext {
  final BuildContext context;
  final int id;

  ItemContext({required this.context, required this.id});

  @override
  bool operator ==(Object other) => other is ItemContext && other.id == id;
}

class TrackItem extends StatelessWidget {
  const TrackItem(this.l, this.index, this.crt);

  final Track l;
  final MainRouteState crt;
  final index;

  Widget _buildTiles(Track root, BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(0.0),
        decoration: new BoxDecoration(
          color: ((crt._currentTrack == l.oid && crt._vs == PlayContext.all ||
                      crt._player.currentIndex == index &&
                          crt._vs == PlayContext.playlist) &&
                  crt._playingPlayList.id == crt._currentPlayList.id)
              ? Colors.blue[300]
              : index % 2 == 1
                  ? Colors.grey[200]
                  : Colors.grey[50],
        ),
        child: Row(
          children: [
            SizedBox(
                height: 40.0,
                width: 40.0,
                child: Checkbox(
                    value: l.is_active,
                    onChanged: (b) {
                      //l.is_active = b as bool;
                    })),
            Container(
              child: Flexible(
                  child: TextButton(
                      style: TextButton.styleFrom(
                        primary: Colors.transparent,
                        minimumSize: const Size.fromHeight(50), // NEW
                      ),
                      child: new Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l.artist + " - " + l.name //+
                            //l.added_date.toString() //+
                            //l.file_path +
                            //"(" +
                            //l.oid.toString()
                            ,
                            style: new TextStyle(
                                fontSize: 13, color: Colors.black),
                          )),
                      onPressed: () => {
                            crt.play(
                                l, crt._currentPlayList, index, crt._tracks)
                          })),
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return _buildTiles(l, context);
  }
}

class PlaylistButton extends StatelessWidget {
  const PlaylistButton(this.playList, this.crState);

  final Playlist playList;
  final MainRouteState crState;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        crState.loadPlaylist(playList, SortOrder.playlist);
      },
      child: new Container(
          //margin: EdgeInsets.,
          child: Text(playList.name, style: new TextStyle(fontSize: 32.0))),
    );
  }
}
