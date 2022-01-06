import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:provider/provider.dart';
import 'package:http/http.dart';



import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:assets_audio_player/assets_audio_player.dart' hide Playlist;

import 'Track.dart';
import 'AppDatabase.dart';
import 'API.dart';
import 'Playlist.dart';
import 'Player.dart';

/*
todo

download played songs
shuffle playing

store playlist data in local json files
download playlists

add settings menu

sort order
date_added
artist name
song name
duration
*/

enum ViewState {
  all,
  playlist
}


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

class _CategoryRouteState extends State<CategoryRoute> {

  AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();

  String? localFilePath;

  List<Track> _tracks = <Track>[];
  Map<int, Track> _tMap = Map<int, Track>();
  Playlist currentSub = new Playlist("o", "123");
  Choice _selectedChoice = choices[0];
  String sortOrder = 'best';

  ViewState _vs = ViewState.all;

  List<Playlist> _playlists = [];

  Player _player = Player();

  Track? current;

  final int _pageSize = 128;

  final PagingController<int, Track> _pagingController =
      PagingController(firstPageKey: 0);

  //bool _isPlaylist = false;

  @override
  void initState() {
    super.initState();
    //DateTime.parse("2000-07-20 20:18:04Z")
    _tracks.add(new Track("Taking Flight", "456", "DROELOE - Taking Flight.flac", artist:"DROELOE"));
    _tracks.add(new Track("Happy Endings", "456", "Mike Shinoda - Happy Endings (feat. iann dior and UPSAHL).flac", artist:"Mike Shinoda"));
    _tracks.add(new Track("The end", "456", "audio.mp3", artist:"the backenders"));

    AppDatabase.openConnection().then((value) => this.refresh());

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    assetsAudioPlayer.playlistAudioFinished.listen((Playing playing){
      print(" music finished");

      //_skip_next();
    });

    fetchPlaylists2();

    print(" initState" + _tracks.length.toString());
  }

  fetchPlaylists2() async {

    try {
      List<Playlist> playlists = await Api.fetchPlaylists("", "");

      playlists.add(new Playlist("All Music", "#ALL#"));

      setState(() {
      _playlists = playlists;
      _vs = ViewState.playlist;
      });

    } catch (e) {
      print("fetchPlaylists2 error: " + e.toString());
    }

    //print(" fetchPlaylists" + _playlists.length.toString());
  }

  Future<void> _fetchPage(pageKey) async {
    //try {

      if (_vs == ViewState.all) {

        List<Track> newItems = [];
        newItems.addAll(await AppDatabase.fetchTracksPage(_pageSize,pageKey));

        final isLastPage = newItems.length < _pageSize;
        if (isLastPage) {
          _pagingController.appendLastPage(newItems);
        } else {
          final nextPageKey = pageKey + newItems.length;
          _pagingController.appendPage(newItems, nextPageKey);
        }

      } else if (_vs == ViewState.playlist) {

        _pagingController.appendLastPage(_tracks);
        
      }
      

      //_pagingController.appendPage(data, pageKey+data.length);
    //} catch (error) {
    //  _pagingController.error = error;
    //}
  }

  Future _loadFile() async {
    final bytes = await readBytes(Uri.parse("kUrl1"));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/DROELOE - Taking Flight.flac');

    await file.writeAsBytes(bytes);
    if (file.existsSync()) {
      setState(() => localFilePath = file.path);
    }
  }

  void _select(Choice choice) {
    setState(() {
      _selectedChoice = choice;
    });
  }

  void _openTrack() {

  }

  void _playTrack(String path) {

    if (Platform.isAndroid || Platform.isIOS) {


      
    } else if (Platform.isWindows) {

    }
    
  }

  void _playTrackStream(Track track) async {

    current = track;

    if (Platform.isAndroid || Platform.isIOS) {
      
      try {
          assetsAudioPlayer.stop();
          await assetsAudioPlayer.open(
              Audio.network("http://192.168.0.105:3000/api/track/"+track.id)
          );

          //assetsAudioPlayer.open(
          //  Audio("assets/DROELOE - Taking Flight.flac"),
          //);
          
          print('playing!');
      } catch (t) {
          print('could not play!');
      }

    } else if (Platform.isWindows) {

    }
    
  }

  void _play_pause() {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      assetsAudioPlayer.playOrPause();
    } else if (Platform.isWindows) {
      
    }
  }

  Future<Track> getNextTrack() async {
    if (current != null) {
      Track c = current as Track;
      print(" ________________________________________________________________________________________________________________________oid " + c.oid.toString());

      Track next = await AppDatabase.fetchNextTrack(c.oid as String , "");
      print("________________________________________" + next.name);
      return next;
    }
    throw Exception();
  }

  Future<Track> getPrevTrack() async {
    if (current != null) {
      Track c = current as Track;
      Track next = await AppDatabase.fetchPrevTrack(c.oid as String , "");
      return next;
    }
    throw Exception();
  }

  void _skip_next() async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {

      assetsAudioPlayer.stop();
      try {
        Track t = await getNextTrack();
        current = t;
        await assetsAudioPlayer.open(
            Audio.network("http://192.168.0.103:8080/api/track/"+t.id)
        );
      } catch (e) {

      }

    } else if (Platform.isWindows) {
      
    }
  }

  void _skip_prev() async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      assetsAudioPlayer.stop();
      try {
        Track t = await getPrevTrack();
        current = t;
        await assetsAudioPlayer.open(
            Audio.network("http://192.168.0.105:8080/api/track/"+t.id)
        );
      } catch (e) {

      }
    } else if (Platform.isWindows) {
      
    }
  }

  void refresh() async {

    final tracks = await Api.fetchTracks("track", sortOrder);

    for (int i = 0; i < tracks.length; i++) {
      AppDatabase.insertTrack(tracks[i]);
    }

    final tracks2 = await AppDatabase.fetchTracks();

    _pagingController.refresh();

    setState(() {
      _tracks = tracks2;
      _pagingController.refresh();
    });

  }

  void refreshPlaylists() async {

    List<Playlist> playlists = await Api.fetchPlaylists("track", sortOrder);

    setState(() {
      _vs = ViewState.playlist;
      _playlists = playlists;
      _pagingController.refresh();
    });

  }

  void loadPlaylist(Playlist playlist) async {

    if (playlist.id == "#ALL#") {
      
      final tracks2 = await AppDatabase.fetchTracks();
      
      setState(() {
      _vs = ViewState.all;
      _tracks = tracks2;
      _pagingController.refresh();
    });
      
    } else {
      final tracksids = await Api.fetchPlaylistsTracks(playlist.id);
      final tracks2 = await AppDatabase.fetchPlaylistTracks(tracksids);//fetchTracksByPlaylist

      setState(() {
      _vs = ViewState.playlist;
      _tracks = tracks2;
      _pagingController.refresh();
    });
      
    }

    final tracksids = await Api.fetchPlaylistsTracks(playlist.id);
    final tracks2 = await AppDatabase.fetchPlaylistTracks(tracksids);

    //_pagingController.appendLastPage(tracks2);
  }

  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
        length: 3,
        child: new Scaffold(
      drawer: new Drawer(

          //child: new Padding(
          //    padding: new EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child:
          Container(
              //height: MediaQuery.of(context).size.height,
              child:
              new ListView.builder(

                //padding: new EdgeInsets.all(8.0),
                itemExtent: 40.0,
                itemCount: _playlists.length,
                itemBuilder: (BuildContext context, int index) {
                  return new SubbRedditButton(_playlists[index], this);
                },
              )

          )
      ),
      appBar:
          new AppBar(
              title: const Text('Whale Music'),
              bottom: new PreferredSize(
                preferredSize: const Size.fromHeight(48.0),
                child: new Theme(
                  data: Theme.of(context).copyWith(accentColor: Colors.white),
                  child: new Container(
                    height: 48.0,
                    alignment: Alignment.center,
                    child:


                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        new Expanded( child: InkWell ( child: Center(child: Text('Best'),), onTap:() {sortOrder = 'best'; refresh(); } ,)),
                        new Expanded( child: InkWell ( child: Center(child: Text('Hot'),), onTap: () {sortOrder = 'hot'; refresh();   } ,)),
                        new Expanded( child: InkWell ( child: Center(child: Text('New'),), onTap: () {sortOrder = 'new'; refresh();   })),
                        new Expanded( child: InkWell ( child: Center(child: Text('Top'),), onTap: () {sortOrder = 'top'; refresh();   })),

                      ],
                    )

                    ,
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

      bottomNavigationBar: 
      new Container(child : 
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
                    MyStatefulWidget(),
      Padding(
        padding: const EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 6.0),
        child:

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          new IconButton(icon: new Icon (Icons.shuffle) ,onPressed: () {},),
          new IconButton(iconSize: 40,icon: new Icon (Icons.skip_previous) ,onPressed: () {_skip_prev();},),
          new IconButton(iconSize: 60,icon: new Icon (Icons.play_arrow) ,onPressed: () { assetsAudioPlayer.playOrPause();},),
          new IconButton(iconSize: 40,icon: new Icon (Icons.skip_next) ,onPressed: () {_skip_next();},),
          new IconButton(icon: new Icon (Icons.loop) ,onPressed: () {},),
          ])
      )
      ])
        ,
        decoration: new BoxDecoration(
          color: Colors.grey[400],
                  )
      )//Text("Player here", style: new TextStyle(fontSize: 16),)
      ,
      
      body: 
      
      _vs == ViewState.playlist ?
      ListView.builder(
        itemCount: _tracks.length,
        itemBuilder: (BuildContext context, int index) {
          return new EntryItem(_tracks[index], index, this);
        },
      )
      :
        PagedListView<int, Track>(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<Track>(
            itemBuilder: (context, item, index) => 
            EntryItem(
              item, index,this
              ),
          ),
        )
        

      /*
      new ListView.builder(
        itemBuilder:  (BuildContext context, int index) {
            return new EntryItem( _tracks[index] , index, this);}, // return sql query here? _tracks[index]  AppDatabase.fetchTrack(index)
        itemCount: _tracks.length,//,
      )
      */
      ,
    ));
  }
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
                    
                    child:Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      
                      children: [
                        new Container(
                          //margin: const EdgeInsets.all(0.0),
                          child:Row( children: [
                            SizedBox(
                            height: 40.0,
                            width: 40.0,
                            child:
                            Checkbox(
                              
                              value: l.is_active, onChanged: (b) {
                              //l.is_active = b as bool;
                              })
                            )
                              ,
                        new Align(
                          //alignment: Alignment.topLeft,
                          child: 
                          InkWell(
                            splashColor: Colors.deepOrange,
                            highlightColor: Colors.deepPurple,
                            onTap: () async {
                              print('tap2!');
                              //final bytes = await (await crt.audioCache.loadAsFile(l.file_path)).readAsBytes();
                              //crt.audioCache.playBytes(bytes);
                              crt._playTrackStream(l);
                            },
                            child: 
                          Column(children: [
                            Text(l.artist + " - " + l.name+l.oid.toString(), style: new TextStyle(fontSize: 13),)
                          ])),
                        )]
                        )
                        )//,
                      ]),
                  decoration: new BoxDecoration(
                    color: index % 2 == 1 ?  Colors.grey[200]: Colors.grey[50],
                  )),
                 //Text('<cmts> (<sub>)')
              ]))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return _buildTiles(l, context);
  }
}
class SubbRedditButton extends StatelessWidget {

  const SubbRedditButton(this.sub, this.crState);

  final Playlist sub;
  final _CategoryRouteState crState;

  @override
  Widget build(BuildContext context) {
    return InkWell(
          onTap: () async {

            crState.setState(
                    () {
              crState.currentSub = sub;
            }
            );
            crState.loadPlaylist(sub);
            crState.refresh();
            print(crState.currentSub);

          },
        child:
      new Container(
        //margin: EdgeInsets.,
      child:
        Text(
            sub.name,
            style: new TextStyle(fontSize: 32.0)
        )
      )
      ,
    );
  }
}

/////////////////////////////////

void main() {
  
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
        primarySwatch: Colors.blue,
      ),
      home: CategoryRoute(),//MyHomePage(title: 'Whale Music Home'),
    );
  }
}


/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
/// AnimationControllers can be created with `vsync: this` because of TickerProviderStateMixin.
class _MyStatefulWidgetState extends State<MyStatefulWidget>
    with TickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });
    controller.repeat(reverse: true);
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
              value: controller.value,
              semanticsLabel: 'Linear progress indicator',
            ),
          ],
        ),
      )
    ;
  }
}