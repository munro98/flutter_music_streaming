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

import 'dart:isolate';
import 'dart:ui';

import 'Player.dart';
import 'Track.dart';
import 'AppDatabase.dart';
import 'API.dart';
import 'Playlist.dart';
import 'SeekBar.dart';

/*
todo

grey out tracks unavailable when offline
looping
improve shuffle playing/ implement for playlists

add settings menu and able to edit server ip

fix added_date sort order
add album sortOrder

detect when track can't be played due to end of playlist/missing connection to server/other reason

able to enable/disable songs in library and playlists
drag and drop song into playlist

sync(play count/ last date played)
delete (unchecked/ least played songs)

## stretch goal ##

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

class CategoryRoute extends StatefulWidget {
  const CategoryRoute();

  @override
  CategoryRouteState createState() => CategoryRouteState();
}

class CategoryRouteState extends State<CategoryRoute> {
  //String? localFilePath;

  final Playlist allPlayList = new Playlist("All Music", "#ALL#");
  final Playlist favouritePlayList = new Playlist("Favourites", "#FAV#");

  List<Track> _tracks = <Track>[];
  late Playlist _currentPlayList = allPlayList;
  late Playlist _playingPlayList = allPlayList;
  Choice _selectedChoice = choices[0];
  String _sortOrder = 'playlist';

  PlayContext _vs = PlayContext.all;
  List<Playlist> _playlists = [];

  late Player _player = Player(this);
  Track? current;

  final int _pageSize = 128;

  Map<int, bool> _pageMapIsFetching = Map<int, bool>();
  Map<int, List<Track>> _pageMap = Map<int, List<Track>>();
  int _pageMapCount = 0;
  int _trackCount = 0;

  String _currentTrack = "";
  bool _shuffleMode = false;
  LoopMode _loopMode = LoopMode.none;
  bool _isConnected = false;

  GlobalKey<SeekBarState> _seekKey = GlobalKey();

  ScrollController _scrollController = new ScrollController();
  //BehaviorSubject<ScrollNotification> _streamController;
  late Set<ItemContext> _itemsContexts;

  final int ignoreEvery = 1000;
  int ignoreCounter = 0;

  //late String _localPath;
  //late bool _permissionReady;
  //List<_TaskInfo>? _tasks;
  //late List<_ItemHolder> _items;
  //late bool _isLoading;

  @override
  void initState() {
    super.initState();

    _itemsContexts = Set<ItemContext>();
    // Initialize a stream controller

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      setState(() {});
    });

    FlutterDownloader.registerCallback(downloadCallback);

    //DateTime.parse("2000-07-20 20:18:04Z")
    _tracks.add(new Track(
        "Taking Flight", "456", "DROELOE - Taking Flight.flac",
        artist: "DROELOE"));
    _tracks.add(new Track("Happy Endings", "456",
        "Mike Shinoda - Happy Endings (feat. iann dior and UPSAHL).flac",
        artist: "Mike Shinoda"));

    //AppDatabase.openConnection().then((value) => this.refresh());
    //AppDatabase.openConnection();
    AppDatabase.openConnection()
        .then((value) => loadPlaylist(_currentPlayList, "playlist"));

    //_permissionReady = false;
    //_isLoading = true;
    _player.init(_currentPlayList);

    fetchPlaylists();
    loadPlaylist(_currentPlayList, "playlist");

    _seekKey.currentState?.stop();

    /*
    StreamBuilder(
        stream: _player.assetsAudioPlayer.currentPosition,
        builder: (context, asyncSnapshot) {
          final bool isPlaying = asyncSnapshot.data as bool;
          return Text(isPlaying ? 'Pause' : 'Play');
        });
    */

    //_player.assetsAudioPlayer.

    _player.assetsAudioPlayer.current.listen((playing) {
      //final path = playing?.audio.path;
      final songDuration = playing?.audio.duration;
      //_seekKey.currentState?.setDurationValue(songDuration!);
      _seekKey.currentState?.reset();

      print("TTTTTTTTTTTTTTTTTTTT " + songDuration.toString());
    });

    print(" initState" + _tracks.length.toString());
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');

    _itemsContexts.clear();

    super.dispose();
  }

  void _onScroll(ScrollUpdateNotification notifications) {
    // Iterate through each item to check
    // whether it is in the viewport
    ignoreCounter++;
    ignoreCounter = ignoreCounter % ignoreEvery;

    if (ignoreCounter != 1) {
      //return;
    }

    for (final ItemContext item in _itemsContexts) {
      // Retrieve the RenderObject, linked to a specific item
      final RenderObject? object = item.context.findRenderObject();

      // If none was to be found, or if not attached, leave by now
      // As we are dealing with Slivers, items no longer part of the
      // viewport will be detached
      if (object == null || !object.attached) {
        return;
      }

      // Retrieve the viewport related to the scroll area
      final RenderAbstractViewport? viewport =
          RenderAbstractViewport.of(object);
      final double? vpHeight = viewport?.paintBounds.height;
      final ScrollableState? scrollableState = Scrollable.of(item.context);
      final ScrollPosition? scrollPosition = scrollableState?.position;
      final RevealedOffset vpOffset = viewport!.getOffsetToReveal(object, 0.0);

      // Retrieve the dimensions of the item
      final Size? size = object.semanticBounds.size;

      // Check if the item is in the viewport
      final double deltaTop = vpOffset.offset - scrollPosition!.pixels;
      final double deltaBottom = deltaTop + size!.height;

      bool isInViewport = false;

      isInViewport = (deltaTop >= 0.0 && deltaTop < vpHeight!);
      if (!isInViewport) {
        isInViewport = (deltaBottom > 0.0 && deltaBottom < vpHeight!);
      }

      print(
          '${item.id} --> offset: ${vpOffset.offset} -- VP?: ${isInViewport}');
    }
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
      print("CategoryRoute.fetchPlaylists error: " + e.toString());
    }
  }

  // TODO: figure when to remove data
  Future<void> _fetchPage(pageKey, String id, String sortOrder) async {
    try {
      if (_pageMapIsFetching.containsKey(pageKey)) return;

      _pageMapIsFetching[pageKey] = true;

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

  void refresh() async {
    final tracks = await Api.fetchTracks("track", _sortOrder);

    for (int i = 0; i < tracks.length; i++) {
      AppDatabase.insertTrack(tracks[i]);
    }
    /*
    final tracks2 = await AppDatabase.fetchTracks();

    setState(() {
      _tracks = tracks2;
    });
    */
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

  void onAction(Choice choice) {
    if (choice.title == 'Refresh') {
      print("CategoryRoute.onAction: " + "refreshPlaylists()");
      refreshPlaylists();
    } else if (choice.title == 'Download Playlist Data') {
      print(
          "CategoryRoute.onAction: " + "PlaylistManager.downloadPlaylists();");
      PlaylistManager.downloadPlaylists();
    } else if (choice.title == "Download Tracks in Playlist") {
      if (_vs == PlayContext.playlist) {
        print("CategoryRoute.onAction: " +
            "PlaylistManager.downloadTracksInPlaylists(_currentPlayList);");
        PlaylistManager.downloadTracksInPlaylists(_currentPlayList);
      }
    }
  }

  void loadPlaylist(Playlist playlist, String sortOrder) async {
    if (playlist.id == "#ALL#") {
      int trackCount = await AppDatabase.fetchTracksCount();
      print("main.loadPlaylist: " + trackCount.toString());
      _fetchPage(0, playlist.id, sortOrder);

      setState(() {
        _sortOrder = sortOrder;
        _itemsContexts.clear();
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
        _itemsContexts.clear();
        _currentPlayList = playlist;
        _trackCount = trackCount;
        _vs = PlayContext.all;
      });
      _pageMap.forEach((k, v) => {_fetchPage(k, playlist.id, sortOrder)});
    } else {
      //final tracksids = await Api.fetchPlaylistsTracks(playlist.id);
      final tracksids = await PlaylistManager.fetchPlaylistsTracks(playlist.id);
      final tracks2 = await AppDatabase.fetchPlaylistTracks(tracksids);

      //refresh();

      setState(() {
        _sortOrder = sortOrder;
        _itemsContexts.clear();
        _currentPlayList = playlist;
        _vs = PlayContext.playlist;
        _tracks = tracks2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
        length: 3,
        child: new Scaffold(
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
                    data: Theme.of(context).copyWith(accentColor: Colors.white),
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
                                Icon(Icons.arrow_drop_down)
                              ],
                            ),
                            onTap: () {
                              loadPlaylist(_currentPlayList, 'name');
                              //refresh();
                            },
                          )),
                          new Expanded(
                              child: InkWell(
                            child: Center(
                              child: Text('Artist'),
                            ),
                            onTap: () {
                              loadPlaylist(_currentPlayList, 'artist');
                            },
                          )),
                          new Expanded(
                              child: InkWell(
                                  child: Center(
                                    child: Text('Date'),
                                  ),
                                  onTap: () {
                                    loadPlaylist(
                                        _currentPlayList, 'added_date');
                                  })),
                          new Expanded(
                              child: InkWell(
                                  child: Center(
                                    child: Text('Playlist'),
                                  ),
                                  onTap: () {
                                    loadPlaylist(_currentPlayList, 'playlist');
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
                            onAction(choice);
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
                ? ListView.builder(
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
                    child: ListView.builder(
                        itemCount: _trackCount,
                        itemBuilder: (context, index) {
                          if (_hasTrack(index)) {
                            return new TrackItem(
                                _fetchTrack(index), index, this);
                          } else {
                            //getMoreData(); // TODO
                            _fetchPage((index ~/ _pageSize).toInt(),
                                _currentPlayList.id, _sortOrder);
                            return Center(child: CircularProgressIndicator());
                          }
                        }),
                  )));
  }

  void play(Track l, Playlist currentPlayList, index, List<Track> tracks) {
    _player.play(l, currentPlayList, index, _tracks, _trackCount);

    _seekKey.currentState?.reset();

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

  String getSortOrder() {
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

// Displays one Entry. If the entry has children then it's displayed
// with an ExpansionTile.
class TrackItem extends StatelessWidget {
  const TrackItem(this.l, this.index, this.crt);

  final Track l;
  final CategoryRouteState crt;
  final index;

  Widget _buildTiles(Track root, BuildContext context) {
    //return new ListTile(title: new Text(root.title));
    crt._itemsContexts.add(ItemContext(
      context: context,
      id: index,
    ));

    return Container(
        margin: const EdgeInsets.all(0.0),
        decoration: new BoxDecoration(
          color: (crt._currentTrack == l.oid &&
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
  final CategoryRouteState crState;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        crState.loadPlaylist(playList, "playlist");
      },
      child: new Container(
          //margin: EdgeInsets.,
          child: Text(playList.name, style: new TextStyle(fontSize: 32.0))),
    );
  }
}
