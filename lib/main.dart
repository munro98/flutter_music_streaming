import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:provider/provider.dart';
import 'package:http/http.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:assets_audio_player/assets_audio_player.dart' hide Playlist;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:android_path_provider/android_path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'dart:isolate';
import 'dart:ui';

import 'Track.dart';
import 'AppDatabase.dart';
import 'API.dart';
import 'Playlist.dart';
import 'Player.dart';

/*
todo

play modes/sort order (song title/song title desc, artist/artist desc, date/date desc, playlist/playlist desc)
shuffle playing
looping
store playlist data in local json files
able to enable/disable songs in library and playlists
drag and drop song into playlist
show songs available on local storage
download playlists

add settings menu

sync(play count/ last date played)
delete (unchecked/ least played songs)

artist view
album view
*/

enum ViewState { all, playlist }

class Choice {
  const Choice(String this.title, IconData this.icon);

  final String title;
  final IconData icon;
}

const List<Choice> choices = const <Choice>[
  const Choice('Button1', Icons.directions_car),
  const Choice('Button2', Icons.directions_boat),
  const Choice('Button3', Icons.directions_bus),
];

class CategoryRoute extends StatefulWidget {
  const CategoryRoute();

  @override
  _CategoryRouteState createState() => _CategoryRouteState();
}

ReceivePort _port = ReceivePort();

class _CategoryRouteState extends State<CategoryRoute> {
  //String? localFilePath;

  final Playlist allPlayList = new Playlist("All Music", "#ALL#");
  final Playlist favouritePlayList = new Playlist("Favourites", "#FAV#");

  List<Track> _tracks = <Track>[];
  late Playlist _currentPlayList = allPlayList;
  late Playlist _playingPlayList = allPlayList;
  Choice _selectedChoice = choices[0];
  String _sortOrder = 'playlist';

  ViewState _vs = ViewState.all;
  List<Playlist> _playlists = [];

  Player _player = Player();
  Track? current;

  final int _pageSize = 128;

  Map<int, bool> _pageMapIsFetching = Map<int, bool>();
  Map<int, List<Track>> _pageMap = Map<int, List<Track>>();
  int _pageMapCount = 0;
  int _trackCount = 0;

  int _currentTrack = -1;

  GlobalKey<_MyStatefulWidgetState> _animationKey = GlobalKey();
  ScrollController _scrollController = new ScrollController();

  //late String _localPath;
  //late bool _permissionReady;
  //List<_TaskInfo>? _tasks;
  //late List<_ItemHolder> _items;
  //late bool _isLoading;

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

    //DateTime.parse("2000-07-20 20:18:04Z")
    _tracks.add(new Track(
        "Taking Flight", "456", "DROELOE - Taking Flight.flac",
        artist: "DROELOE"));
    _tracks.add(new Track("Happy Endings", "456",
        "Mike Shinoda - Happy Endings (feat. iann dior and UPSAHL).flac",
        artist: "Mike Shinoda"));
    _tracks.add(
        new Track("The end", "456", "audio.mp3", artist: "the backenders"));

    //AppDatabase.openConnection().then((value) => this.refresh());
    //AppDatabase.openConnection();
    AppDatabase.openConnection().then((value) => loadPlaylist(allPlayList));

    //_permissionReady = false;
    //_isLoading = true;
    _player.init(_currentPlayList);

    fetchPlaylists2();
    loadPlaylist(_currentPlayList);

    _animationKey.currentState?.stop();

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
      //_animationKey.currentState?.setDurationValue(songDuration!);
      _animationKey.currentState?.reset();

      print("TTTTTTTTTTTTTTTTTTTT " + songDuration.toString());
    });

    print(" initState" + _tracks.length.toString());
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  fetchPlaylists2() async {
    //print(" fetchPlaylists" + _playlists.length.toString());
    try {
      List<Playlist> playlists = await Api.fetchPlaylists("", "");
      playlists.add(new Playlist("All Music", "#ALL#"));

      setState(() {
        _playlists = playlists;
        _vs = ViewState.playlist;
      });
    } catch (e) {
      print("main.fetchPlaylists2 error: " + e.toString());
    }
  }

  // TODO: figure when to remove data
  Future<void> _fetchPage(pageKey) async {
    try {
      if (_pageMapIsFetching.containsKey(pageKey)) return;

      _pageMapIsFetching[pageKey] = true;

      var data =
          await AppDatabase.fetchTracksPage(_pageSize, pageKey, _sortOrder);

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
    final tracks2 = await AppDatabase.fetchTracks();

    setState(() {
      _tracks = tracks2;
    });
  }

  void refreshPlaylists() async {
    List<Playlist> playlists = await Api.fetchPlaylists("track", _sortOrder);

    playlists.insert(0, allPlayList);

    setState(() {
      _vs = ViewState.playlist;
      _playlists = playlists;
    });
  }

  void loadPlaylist(Playlist playlist) async {
    if (playlist.id == "#ALL#") {
      _fetchPage(0);
      int trackCount = await AppDatabase.fetchTracksCount();
      print("main.loadPlaylist: " + trackCount.toString());

      setState(() {
        //_pageMap.clear(); // TODO: is this needed?
        //_pageMapCount = 0;
        //_pageMapIsFetching.clear();
        _currentPlayList = playlist;
        _trackCount = trackCount;
        _vs = ViewState.all;
      });

      _pageMap.forEach((k, v) => {_fetchPage(k)});
    } else {
      final tracksids = await Api.fetchPlaylistsTracks(playlist.id);
      final tracks2 = await AppDatabase.fetchPlaylistTracks(tracksids);

      setState(() {
        _currentPlayList = playlist;
        _vs = ViewState.playlist;
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
              title: const Text('Whale Music'),
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
                              Text('By Song'),
                              Icon(Icons.arrow_drop_down)
                            ],
                          ),
                          onTap: () {
                            _sortOrder = 'name';
                            loadPlaylist(_currentPlayList);
                            //refresh();
                          },
                        )),
                        new Expanded(
                            child: InkWell(
                          child: Center(
                            child: Text('Artist'),
                          ),
                          onTap: () {
                            _sortOrder = 'artist';
                            loadPlaylist(_currentPlayList);
                          },
                        )),
                        new Expanded(
                            child: InkWell(
                                child: Center(
                                  child: Text('Date'),
                                ),
                                onTap: () {
                                  _sortOrder = 'added_date';
                                  loadPlaylist(_currentPlayList);
                                })),
                        new Expanded(
                            child: InkWell(
                                child: Center(
                                  child: Text('Playlist'),
                                ),
                                onTap: () {
                                  _sortOrder = 'playlist';
                                  loadPlaylist(_currentPlayList);
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
                          refreshPlaylists();
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
                    MyStatefulWidget(this, key: _animationKey),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 6.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              new IconButton(
                                icon: new Icon(Icons.shuffle),
                                onPressed: () {},
                              ),
                              new IconButton(
                                iconSize: 40,
                                icon: new Icon(Icons.skip_previous),
                                onPressed: () {
                                  _player.skip_prev();
                                },
                              ),
                              new IconButton(
                                iconSize: 60,
                                icon: new Icon(Icons.play_arrow),
                                onPressed: () {
                                  _player.playOrPause();
                                },
                              ),
                              new IconButton(
                                iconSize: 40,
                                icon: new Icon(Icons.skip_next),
                                onPressed: () {
                                  _player.skip_next();
                                },
                              ),
                              new IconButton(
                                icon: new Icon(Icons.loop),
                                onPressed: () {},
                              ),
                            ]))
                  ]),
              decoration: new BoxDecoration(
                color: Colors.grey[400],
              )) //Text("Player here", style: new TextStyle(fontSize: 16),)
          ,
          body: _vs == ViewState.playlist
              ? ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (BuildContext context, int index) {
                    return new EntryItem(_tracks[index], index, this);
                  },
                )
              : ListView.builder(
                  itemCount: _trackCount,
                  itemBuilder: (context, index) {
                    if (_hasTrack(index)) {
                      return new EntryItem(_fetchTrack(index), index, this);
                    } else {
                      //getMoreData(); // TODO
                      _fetchPage((index ~/ _pageSize).toInt());
                      return Center(child: CircularProgressIndicator());
                    }
                  }),
        ));
  }

  void play(Track l, Playlist currentPlayList, index, List<Track> tracks) {
    _player.play(l, currentPlayList, index, _tracks);

    this.setState(() {
      this._currentTrack = index;
      this._playingPlayList = currentPlayList;
    });
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
class EntryItem extends StatelessWidget {
  const EntryItem(this.l, this.index, this.crt);

  final Track l;
  final _CategoryRouteState crt;
  final index;

  Widget _buildTiles(Track root, BuildContext context) {
    //return new ListTile(title: new Text(root.title));

    return GestureDetector(
        onHorizontalDragStart: (DragStartDetails d) {
          print("dragStart");
        },
        onHorizontalDragEnd: (DragEndDetails d) async {
          print("dragEnd");
        },
        child: Row(children: [
          new Flexible(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                new Container(
                    //margin: const EdgeInsets.all(8.0),

                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          new Container(
                              //margin: const EdgeInsets.all(0.0),
                              child: Row(children: [
                            SizedBox(
                                height: 40.0,
                                width: 40.0,
                                child: Checkbox(
                                    value: l.is_active,
                                    onChanged: (b) {
                                      //l.is_active = b as bool;
                                    })),
                            new Align(
                              //alignment: Alignment.topLeft,
                              child: InkWell(
                                  splashColor: Colors.deepOrange,
                                  highlightColor: Colors.deepPurple,
                                  onTap: () async {
                                    print('tap2!');
                                    //final bytes = await (await crt.audioCache.loadAsFile(l.file_path)).readAsBytes();
                                    //crt.audioCache.playBytes(bytes);
                                    //playingPlayList
                                    crt.play(l, crt._currentPlayList, index,
                                        crt._tracks);
                                  },
                                  child: Column(children: [
                                    Text(
                                      l.artist +
                                          " - " +
                                          l.name +
                                          //l.file_path +
                                          "(" +
                                          l.oid.toString(),
                                      style: new TextStyle(fontSize: 13),
                                    )
                                  ])),
                            )
                          ])) //,
                        ]),
                    decoration: new BoxDecoration(
                      color: (crt._currentTrack == index &&
                              crt._playingPlayList.id ==
                                  crt._currentPlayList.id)
                          ? Colors.blue[300]
                          : index % 2 == 1
                              ? Colors.grey[200]
                              : Colors.grey[50],
                    )),
              ]))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return _buildTiles(l, context);
  }
}

class PlaylistButton extends StatelessWidget {
  const PlaylistButton(this.playList, this.crState);

  final Playlist playList;
  final _CategoryRouteState crState;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        crState.loadPlaylist(playList);
        crState.refresh();
        //print(crState.currentPlayList);
      },
      child: new Container(
          //margin: EdgeInsets.,
          child: Text(playList.name, style: new TextStyle(fontSize: 32.0))),
    );
  }
}

/////////////////////////////////
const debug = true;
void main() async {
  await FlutterDownloader.initialize(debug: debug);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whale Music',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.grey,
      ),
      home: CategoryRoute(), //MyHomePage(title: 'Whale Music Home'),
    );
  }
}

/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget(this.crt, {Key? key}) : super(key: key);

  final _CategoryRouteState crt;

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState(crt);
}

/// This is the private State class that goes with MyStatefulWidget.
/// AnimationControllers can be created with `vsync: this` because of TickerProviderStateMixin.
class _MyStatefulWidgetState extends State<MyStatefulWidget>
    with TickerProviderStateMixin {
  late AnimationController controller;

  final _CategoryRouteState crt;
  double progressBarValue = 0.0;

  _MyStatefulWidgetState(this.crt);

  void reset() {
    controller.reset();
  }

  void stop() {
    controller.stop();
  }

  void setProgressValue(double val) {
    this.setState(() {
      controller.value = val;
    });
  }

  void setDurationValue(Duration duration) {
    this.setState(() {
      controller.duration = duration;
    });
  }

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..addListener(() {
        setState(() {});
      });
    //controller.
    controller.repeat(reverse: false);
    //controller.
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 4.0),
      child: Column(
        //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LinearProgressIndicator(
            value: controller
                .value, //crt._player.assetsAudioPlayer.currentPosition.inSeconds.toDouble() / crt._player.assetsAudioPlayer.duration.inSeconds.toDouble()
            semanticsLabel: 'Linear progress indicator',
          ),
        ],
      ),
    );
  }
}

class _TaskInfo {
  final String? name;
  final String? link;

  String? taskId;
  int? progress = 0;
  DownloadTaskStatus? status = DownloadTaskStatus.undefined;

  _TaskInfo({this.name, this.link});
}

class _ItemHolder {
  final String? name;
  final _TaskInfo? task;

  _ItemHolder({this.name, this.task});
}
