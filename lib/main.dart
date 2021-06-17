import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart';
//import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:assets_audio_player/assets_audio_player.dart';

//import 'player_widget.dart';

import 'Track.dart';
import 'AppDatabase.dart';


List<String> playlists = <String>["ONE","two", "three"];

class Choice {
  const Choice({this.title, this.icon});

  final String? title;
  final IconData? icon;
}

const List<Choice> choices = const <Choice>[
  const Choice(title: 'Button1', icon: Icons.directions_car),
  const Choice(title: 'Button2', icon: Icons.directions_boat),
  const Choice(title: 'Button3', icon: Icons.directions_bus),
];

class CategoryRoute extends StatefulWidget {
  const CategoryRoute();

  @override
  _CategoryRouteState createState() => _CategoryRouteState();
}

class _CategoryRouteState extends State<CategoryRoute> {

  
  //AudioPlayer advancedPlayer = AudioPlayer();
  //AudioCache audioCache = AudioCache(fixedPlayer: AudioPlayer());
  AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();

  String? localFilePath;

  List<Track> _tracks = <Track>[];
  Map<int, Track> _tMap = Map<int, Track>();
  String currentSub = 'all';
  Choice _selectedChoice = choices[0]; // The app's "state".
  String sortOrder = 'best';

  int _pageSize = 128;
  int currTracksLoaded = 0;

  final PagingController<int, Track> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    //DateTime.parse("2000-07-20 20:18:04Z")
    _tracks.add(new Track("Taking Flight", "456", "DROELOE - Taking Flight.flac", artist:"DROELOE"));
    _tracks.add(new Track("Happy Endings", "456", "Mike Shinoda - Happy Endings (feat. iann dior and UPSAHL).flac", artist:"Mike Shinoda"));
    _tracks.add(new Track("The end", "456", "audio.mp3", artist:"the backenders"));

    AppDatabase.openConnection();

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    print(" initState" + _tracks.length.toString());
  }

  Future<void> _fetchPage(pageKey) async {
    //try {
      List<Track> newItems = [];
      newItems.addAll(await AppDatabase.fetchTracksPage(_pageSize,pageKey));

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }

      /*
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
      */
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

  void _playTrackStream(String path) async {

    if (Platform.isAndroid || Platform.isIOS) {
      int result = 1;//await advancedPlayer.play("http://172.17.68.97:8080/blackmillmiracle.mp3");//"http://192.168.0.121:8080/api/track/60711e1e84597a84e8904e58");
      
      try {
          assetsAudioPlayer.stop();
          await assetsAudioPlayer.open(
              Audio.network("http://192.168.0.121:8080/api/track/"+path)//Audio.network("http://192.168.0.103:8080/blackmillmiracle.mp3"),   
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

  void _skip_next() {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      
    } else if (Platform.isWindows) {
      
    }
  }

  void _skip_prev() {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      
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
                itemCount: playlists.length,
                itemBuilder: (BuildContext context, int index) {
                  return new SubbRedditButton(playlists[index], this);
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
                child: new Text("choice.title"),
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
          new IconButton(iconSize: 40,icon: new Icon (Icons.skip_previous) ,onPressed: () {},),
          new IconButton(iconSize: 60,icon: new Icon (Icons.play_arrow) ,onPressed: () { assetsAudioPlayer.playOrPause();},),
          new IconButton(iconSize: 40,icon: new Icon (Icons.skip_next) ,onPressed: () {},),
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
                              crt._playTrackStream(l.id);
                            },
                            child: 
                          Column(children: [
                            Text(l.artist + " - " + l.name, style: new TextStyle(fontSize: 13),)
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

  final String sub;
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
            crState.refresh();
            print(crState.currentSub);

          },
        child:
      new Container(
        //margin: EdgeInsets.,
      child:
        Text(
            sub,
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

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}




/////////////////////






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