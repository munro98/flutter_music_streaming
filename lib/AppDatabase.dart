import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:android_path_provider/android_path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'FileUtil.dart';

import 'Track.dart';
import 'Player.dart';

class AppDatabase {
  static Future<Database>? database;
  static DatabaseFactory? databaseFactory;

  static Future<void> openConnection() async {
    /*
    database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'music_library2.db'),
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          //"CREATE TABLE track(id BINARY(12) PRIMARY KEY, name TEXT, file_path TEXT, artist TEXT)",
          "CREATE TABLE track(id BINARY(12) PRIMARY KEY, name TEXT collate nocase, file_path TEXT UNIQUE, artist TEXT collate nocase, release_date TEXT, added_date TEXT, last_played_date TEXT, year INT, genre TEXT, artists TEXT, is_active BOOL, is_missing BOOL, is_downloaded BOOL, play_count INT, track INT, track_of INT, disk INT, disk_of INT, album TEXT, duration INT, size INT, format TEXT)",
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 2,
    );
    */

    ///*
    var databaseFactory = databaseFactoryFfi;
    database = databaseFactory.openDatabase(
        join(await FileUtil.getAppDocDir("/Whale Music"),
            'music_library3.db'), //inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (Database db, int version) async {
              await db.execute(
                "CREATE TABLE track(id BINARY(12) PRIMARY KEY, name TEXT collate nocase, file_path TEXT UNIQUE, artist TEXT collate nocase, release_date TEXT, added_date TEXT, last_played_date TEXT, year INT, genre TEXT, artists TEXT, is_active BOOL, is_missing BOOL, is_downloaded BOOL, play_count INT, track INT, track_of INT, disk INT, disk_of INT, album TEXT, duration INT, size INT, format TEXT, search_keys TEXT)",
              );
            }));

    //*/
  }

  static Future<void> checkTrackIsDownloaded() async {
    if (Platform.isAndroid) {
      bool _permissionReady = await FileUtil.checkPermission();
      if (_permissionReady) {
        final Database db = await (database as Future<Database>);

        final List<Map<String, dynamic>> maps =
            await db.query('track', columns: ['rowid', '*']);

        var externalStorageDirPath =
            await AndroidPathProvider.musicPath + "/Whale Music";

        for (var e in maps.where((e) => e['name'] == "Erase Me")) {
          print("AppDatabase.checkTrackIsDownloaded: " + e.toString());
        }

        print("AppDatabase.checkTrackIsDownloaded" + maps.length.toString());

        final List<Map<String, dynamic>> maps_mutable =
            maps.map((e) => Map.of(e)).cast<Map<String, dynamic>>().toList();

        await Future.wait(maps_mutable.map((e) async {
          try {
            //e['is_downloaded'] = 5;
            //print("e['is_downloaded']" + e['is_downloaded'].toString());
            final file = File('${externalStorageDirPath}/${e['file_path']}');
            e['is_downloaded'] = await file.exists() ? 1 : 0;
          } catch (e) {
            print("AppDatabase.checkTrackIsDownloaded: " + e.toString());
          }
        }));
        /* await Future.forEach(maps_mutable, (Map<String, dynamic> e) async {
          try {
            //final file = File('${externalStorageDirPath}/${e['file_path']}');
            
            //maps_mutable[]
            //e['is_downloaded'] = await file.exists() ? 1 : 0;
            //String isDl = await file.exists() ? "1" : "0";
            //print(e['name'] + isDl);
            //print(e['name'] + e['is_downloaded'].toString());
          } catch (e) {
            print("AppDatabase.checkTrackIsDownloaded: " + e.toString());
          }
        }); */

        for (var e in maps_mutable.where((e) => e['name'] == "Erase Me")) {
          /* print(
              "shold happen after" + e['name'] + e['is_downloaded'].toString()); */
          print("AppDatabase.checkTrackIsDownloaded: " + e.toString());
        }

        Batch batch = db.batch();
        try {
          maps_mutable.forEach((e) {
            batch.insert(
              'track',
              e,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          });

          await batch.commit(noResult: true);
        } catch (e) {
          print("AppDatabase.checkTrackIsDownloaded: " + e.toString());
        }
      }
    }

    /* Map<String, dynamic> map1 = {'name': "Hello", 'is_downloaded': 0};
        final List<Map<String, dynamic>> maps = [map1];
        await Future.wait(maps.map((e) async {
          try {
            e['is_downloaded'] = 5;
            print("e['is_downloaded']" + e['is_downloaded'].toString());
          } catch (e) {
            print("AppDatabase.checkTrackIsDownloaded: " + e.toString());
          }
        }));
      }
    } */
    //print(maps[0].toString());

    /* maps.forEach((e) {
      try {
        final file = File('${externalStorageDirPath}/${e['file_path']}');

        file.exists().then((value) => e['is_downloaded'] = value);
      } catch (e) {}
    }); */
  }

  static Future<void> insertTrackList(List<Track> tracks) async {
    // Get a reference to the database.
    final Database db = await (database as Future<Database>);

    Batch batch = db.batch();
    tracks.forEach((e) {
      batch.insert(
        'track',
        e.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    await batch.commit(noResult: true);
  }

  static Future<void> insertTrack(Track track) async {
    // Get a reference to the database.
    final Database db = await (database as Future<Database>);

    if (track.is_active == 0) {
      print(track.file_path);
    }

    // In this case, replace any previous data.
    await db.insert(
      'track',
      track.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static void syncDatabase() async {}

  static Future<List<Track>> fetchTracks() async {
    print("AppDatabase.fetchTracks:");
    // Get a reference to the database.

    try {
      final Database db = await (database as Future<Database>);

      // Query the table
      final List<Map<String, dynamic>> maps =
          await db.query('track', columns: ['rowid', '*']);

      print("AppDatabase.fetchTracks: Log " + maps[0].toString());

      List<Track> tracks = List.generate(maps.length, (i) {
        return Track(
          maps[i]['name'],
          maps[i]['id'],
          maps[i]['file_path'],
          artist: maps[i]['artist'],
          oid: maps[i]['rowid'].toString(),
        );
      });

      for (int i = 0; i < tracks.length; i++) {
        // WHAT: HOW DOES THIS EVEN WORK!!!!????
        tracks[i].oid = maps[i]['rowid'].toString();
        tracks[i].playlist_index = i;
        tracks[i].is_active = maps[i]['is_active'];

        tracks[i].is_downloaded = maps[i]['is_downloaded'];

        if (maps[i]['added_date'] != null) {
          tracks[i].added_date = maps[i]['added_date'];
        }
      }

      return tracks;
    } catch (e) {
      print("AppDatabase.fetchTracks: Error " + e.toString());
      return [];
    }
  }

  static Future<List<Track>> fetchTracksFavourites() async {
    print("AppDatabase.fetchTracksFavourites:");
    // Get a reference to the database.

    try {
      final Database db = await (database as Future<Database>);

      // Query the table
      final List<Map<String, dynamic>> maps = await db.query(
        'track',
        columns: ['rowid', '*'],
        where: 'is_active = ?',
        whereArgs: [1],
      );

      print("AppDatabase.fetchTracksPage: Error " + maps[0].toString());

      List<Track> tracks = List.generate(maps.length, (i) {
        return Track(
          maps[i]['name'],
          maps[i]['id'],
          maps[i]['file_path'],
          artist: maps[i]['artist'],
          oid: maps[i]['rowid'].toString(),
        );
      });

      for (int i = 0; i < tracks.length; i++) {
        // WHAT: HOW DOES THIS EVEN WORK!!!!????
        tracks[i].oid = maps[i]['rowid'].toString();
        tracks[i].playlist_index = i;
        tracks[i].is_active = maps[i]['is_active'];

        tracks[i].is_downloaded = maps[i]['is_downloaded'];

        if (maps[i]['added_date'] != null) {
          tracks[i].added_date = maps[i]['added_date'];
        }
      }

      return tracks;
    } catch (e) {
      print("AppDatabase.fetchTracksPage: Error " + e.toString());
      return [];
    }
  }

  /* static Future<int> fetchTracksCount() async {
    try {
      final Database db = await (database as Future<Database>);
      final List<Map<String, dynamic>> maps =
          await db.rawQuery('SELECT COUNT(*) FROM track');
      return maps[0]["COUNT(*)"];
    } catch (e) {}
    return 0;
  }

  static Future<int> fetchTracksCountFav() async {
    try {
      final Database db = await (database as Future<Database>);
      final List<Map<String, dynamic>> maps =
          await db.rawQuery('SELECT COUNT(*) FROM track WHERE is_active = 1');
      return maps[0]["COUNT(*)"];
    } catch (e) {}
    return 0;
  } */

  /* static Future<List<Track>> fetchTracksPage(
      int _limit, int offset, SortOrder sortOrder) async {
    try {
      print("AppDatabase.fetchTracksPage:");
      // Get a reference to the database.
      final Database db = await (database as Future<Database>);

      // Query the table
      //final List<Map<String, dynamic>> maps = await db.query('track', where: 'rowid > ?', whereArgs: [id],
      //orderBy: 'rowid', limit: _limit);
      //final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT * FROM track WHERE rowid NOT IN ( SELECT rowid FROM track ORDER BY rowid ASC LIMIT 50 ) ORDER BY rowid ASC LIMIT 10');
      final List<Map<String, dynamic>> maps;

      // https://gist.github.com/ssokolow/262503\
      maps = await db.rawQuery(
          'SELECT rowid as oid, * FROM track WHERE oid NOT IN ( SELECT oid FROM track ORDER BY oid ASC LIMIT ' +
              offset.toString() +
              ' )ORDER BY oid');

      List<Track> tracks = List.generate(maps.length, (i) {
        return Track(
          maps[i]['name'],
          maps[i]['id'],
          maps[i]['file_path'],
          artist: maps[i]['artist'],
          oid: maps[i]['oid'].toString(),
        );
      });

      print("fetching tracks " + tracks.length.toString());

      for (int i = 0; i < tracks.length; i++) {
        // WHAT: HOW DOES THIS EVEN WORK!!!!????
        tracks[i].oid = maps[i]['oid'].toString();

        if (maps[i]['added_date'] != null) {
          tracks[i].added_date = maps[i]['added_date'];
        }
      }
      //print("fetching trackssdfgasdgd " + maps[0]['oid'].toString());
      //print("fetching trackssdfgasdgd " + tracks[0].oid.toString());

      return tracks;
    } catch (e) {
      print(
          "AppDatabase.fetchTracksPage:fetching tracks error " + e.toString());
      return [];
    }
  } */

  static Future<List<Track>> fetchTracksSearch(
      SortOrder sortOrder, bool sortReverse, String search) async {
    try {
      print("AppDatabase.fetchTracksPage:");
      // Get a reference to the database.
      final Database db = await (database as Future<Database>);

      var searchSplit = search.split(' ');
      String s = "";

      for (int i = 0; i < searchSplit.length; i++) {
        searchSplit[i] = searchSplit[i].trim();
      }
      searchSplit.removeWhere((e) => e.length == 0);
      searchSplit.forEach((element) =>
          {s += 'search_keys LIKE "%' + element.toString() + '%" AND '});
      if (s.isNotEmpty) {
        s = s.substring(0, s.length - 1 - 3);
      }

      var q = 'SELECT rowid, * FROM track WHERE ' +
          (searchSplit.length > 0 ? (' (' + s + ')') : (' )')) +
          ' ORDER BY rowid';

      print(q);

      //return [];
      final List<Map<String, dynamic>> maps;
      if (sortOrder == SortOrder.playlist && !sortReverse) {
        maps = await db.rawQuery('SELECT rowid, * FROM track WHERE ' +
            (searchSplit.length > 0 ? (' (' + s + ')') : (' )')) +
            ' ORDER BY rowid');
      } else if (sortOrder == SortOrder.playlist) {
        maps = await db.rawQuery('SELECT rowid, * FROM track WHERE ' +
            (searchSplit.length > 0 ? (' (' + s + ')') : (' )')) +
            ' ORDER BY rowid DESC');
      } else if (sortOrder == SortOrder.name && !sortReverse) {
        maps = await db.rawQuery('SELECT rowid, * FROM track WHERE ' +
            (searchSplit.length > 0 ? (' (' + s + ')') : (' )')) +
            ' ORDER BY name');
      } else if (sortOrder == SortOrder.name) {
        maps = await db.rawQuery('SELECT rowid, * FROM track WHERE ' +
            (searchSplit.length > 0 ? (' (' + s + ')') : (' )')) +
            ' ORDER BY name DESC');
      } else if (sortOrder == SortOrder.artist && !sortReverse) {
        maps = await db.rawQuery('SELECT rowid, * FROM track WHERE ' +
            (searchSplit.length > 0 ? (' (' + s + ')') : (' )')) +
            ' ORDER BY artist');
      } else if (sortOrder == SortOrder.artist) {
        maps = await db.rawQuery('SELECT rowid, * FROM track WHERE ' +
            (searchSplit.length > 0 ? (' (' + s + ')') : (' )')) +
            ' ORDER BY artist DESC');
      } else if (sortOrder == SortOrder.added && !sortReverse) {
        maps = await db.rawQuery('SELECT rowid, * FROM track WHERE ' +
            (searchSplit.length > 0 ? (' (' + s + ')') : (' )')) +
            ' ORDER BY added_date');
      } else {
        maps = await db.rawQuery('SELECT rowid, * FROM track WHERE ' +
            (searchSplit.length > 0 ? (' (' + s + ')') : (' )')) +
            ' ORDER BY added_date DESC');
      }

      List<Track> tracks = List.generate(maps.length, (i) {
        return Track(
          maps[i]['name'],
          maps[i]['id'],
          maps[i]['file_path'],
          artist: maps[i]['artist'],
          oid: maps[i]['rowid'].toString(),
        );
      });

      print("fetching tracks " + tracks.length.toString());

      for (int i = 0; i < tracks.length; i++) {
        // WHAT: HOW DOES THIS EVEN WORK!!!!????
        tracks[i].oid = maps[i]['rowid'].toString();
        tracks[i].is_active = maps[i]['is_active'];

        tracks[i].is_downloaded = maps[i]['is_downloaded'];

        if (maps[i]['added_date'] != null) {
          tracks[i].added_date = maps[i]['added_date'];
        }
      }
      //print("fetching trackssdfgasdgd " + maps[0]['oid'].toString());
      //print("fetching trackssdfgasdgd " + tracks[0].oid.toString());

      return tracks;
    } catch (e) {
      print(
          "AppDatabase.fetchTracksPage:fetching tracks error " + e.toString());
      return [];
    }
  }

  static Future<Track> fetchTrack(String id) async {
    print("AppDatabase.fetchtrack:");
    // Get a reference to the database.
    final Database db = await (database as Future<Database>);

    // Query the table
    final List<Map<String, dynamic>> maps =
        await db.query('track', where: 'id = ?', whereArgs: [id]);

    Track t = Track(
      maps[0]['name'],
      maps[0]['id'],
      maps[0]['file_path'],
      artist: maps[0]['artist'],
    );

    if (maps[0]['added_date'] != null) {
      t.added_date = maps[0]['added_date'];
    }

    return t;
  }

  /* static Future<Track> fetchNextTrack(
      String id, SortOrder sortOrder, bool sortReversed) async {
    print("fetching track " + id);
    // Get a reference to the database.
    final Database db = await (database as Future<Database>);

    //sortOrder == SortOrder.playlist
    //final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT rowid as oid, * FROM track WHERE oid > '+ id + ' ORDER BY oid ASC LIMIT ' + '1');

    try {
      // get name of current track
      final List<Map<String, dynamic>> maps1 = await db
          .rawQuery('SELECT rowid as oid, * FROM track WHERE oid = ' + id);

      String findName = maps1[0]['name'];
      String findArtist = maps1[0]['artist'];
      //String findDate = maps1[0]['added_date'];
      int findId = maps1[0]['oid'];

      final List<Map<String, dynamic>> maps;

      // get first track with same name if index is after current track or name > current track
      if (sortOrder == SortOrder.playlist && !sortReversed) {
        maps = await db.rawQuery('SELECT rowid, * FROM track WHERE oid > ' +
            id +
            ' ORDER BY rowid ASC LIMIT ' +
            '1');
      } else if (sortOrder == SortOrder.playlist) {
        maps = await db.rawQuery('SELECT rowid, * FROM track WHERE oid < ' +
            id +
            ' ORDER BY rowid DESC LIMIT ' +
            '1');
      } else if (sortOrder == SortOrder.name) {
        maps = await db.query('track',
            where:
                'artist >= (SELECT artist FROM track WHERE rowid = ?) COLLATE NOCASE',
            whereArgs: [findId],
            orderBy: 'name COLLATE NOCASE ASC, rowid ASC',
            columns: ['rowid', '*'],
            limit: 1);
      } else if (sortOrder == SortOrder.name && !sortReversed) {
        maps = await db.query('track',
            where:
                'artist >= (SELECT artist FROM track WHERE rowid = ?) COLLATE NOCASE',
            whereArgs: [findId],
            orderBy: 'name COLLATE NOCASE DESC, rowid ASC',
            columns: ['rowid', '*'],
            limit: 1);
      } else if (sortOrder == SortOrder.artist && !sortReversed) {
        // TODO: add
        maps = await db.query('track',
            where:
                'artist >= (SELECT artist FROM track WHERE rowid = ?) COLLATE NOCASE',
            whereArgs: [findId],
            orderBy: 'artist COLLATE NOCASE ASC, rowid ASC',
            columns: ['rowid', '*'],
            limit: 1);
      } else if (sortOrder == SortOrder.artist) {
        maps = await db.query('track',
            where:
                'artist >= (SELECT artist FROM track WHERE rowid = ?) COLLATE NOCASE',
            whereArgs: [findId],
            orderBy: 'artist COLLATE NOCASE DESC, rowid ASC',
            columns: ['rowid', '*'],
            limit: 1);
      }
      else if (sortOrder == SortOrder.added && !sortReversed) {
        maps = await db.rawQuery('SELECT rowid as oid, * FROM track WHERE ' +
            '(added_date = \'' +
            findDate +
            '\' and oid > ' +
            findId.toString() +
            ' ) or (added_date > \'' +
            findDate +
            '\' ) ORDER BY added_date ASC LIMIT ' +
            '1');
      } else if (sortOrder == SortOrder.added) {
        maps = await db.rawQuery('SELECT rowid as oid, * FROM track WHERE ' +
            '(added_date = \'' +
            findDate +
            '\' and oid < ' +
            findId.toString() +
            ' ) or (added_date < \'' +
            findDate +
            '\' ) ORDER BY added_date DESC LIMIT ' +
            '1');
      } 
      else {
        maps = await db.rawQuery('SELECT rowid, * FROM track WHERE oid > ' +
            id +
            ' ORDER BY rowid ASC LIMIT ' +
            '1');
      }

      Track t = Track(
        maps[0]['name'],
        maps[0]['id'],
        maps[0]['file_path'],
        artist: maps[0]['artist'],
        oid: maps[0]['rowid'].toString(),
      );
      t.oid = maps[0]['rowid'].toString();
      if (maps[0]['added_date'] != null) {
        t.added_date = maps[0]['added_date'];
      }

      return t;
    } catch (e) {
      print("fetching tracks error " + e.toString());
    }
    return Track("", "", "");
  } */

  //Favourites Code
  //////////////////////////////////////////////////////////////////////////////

  /* static Future<List<Track>> fetchTracksPageFav(
      int _limit, int offset, SortOrder sortOrder) async {
    try {
      print("AppDatabase.fetchTracksPage:");
      // Get a reference to the database.
      final Database db = await (database as Future<Database>);

      // Query the table
      //final List<Map<String, dynamic>> maps = await db.query('track', where: 'rowid > ?', whereArgs: [id],
      //orderBy: 'rowid', limit: _limit);
      //final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT * FROM track WHERE rowid NOT IN ( SELECT rowid FROM track ORDER BY rowid ASC LIMIT 50 ) ORDER BY rowid ASC LIMIT 10');
      final List<Map<String, dynamic>> maps;

      // https://gist.github.com/ssokolow/262503\
      if (sortOrder == SortOrder.playlist) {
        maps = await db.rawQuery(
            'SELECT rowid as oid, * FROM track WHERE oid NOT IN ( SELECT oid FROM track WHERE is_active = 1 ORDER BY oid ASC LIMIT ' +
                offset.toString() +
                ' )ORDER BY oid ASC LIMIT ' +
                _limit.toString());
      } else if (sortOrder == SortOrder.playlist_desc) {
        maps = await db.rawQuery(
            'SELECT rowid as oid, * FROM track WHERE oid NOT IN ( SELECT oid FROM track WHERE is_active = 1 ORDER BY oid ASC LIMIT ' +
                offset.toString() +
                ' )ORDER BY oid DESC LIMIT ' +
                _limit.toString());
      } else if (sortOrder == SortOrder.name) {
        maps = await db.rawQuery(
            'SELECT rowid as oid, * FROM track WHERE oid NOT IN ( SELECT oid FROM track WHERE is_active = 1 ORDER BY name ASC LIMIT ' +
                offset.toString() +
                ' )ORDER BY name ASC LIMIT ' +
                _limit.toString());
      } else if (sortOrder == SortOrder.name_desc) {
        maps = await db.rawQuery(
            'SELECT rowid as oid, * FROM track WHERE oid NOT IN ( SELECT oid FROM track WHERE is_active = 1 ORDER BY name ASC LIMIT ' +
                offset.toString() +
                ' )ORDER BY name DESC LIMIT ' +
                _limit.toString());
      } else if (sortOrder == SortOrder.artist) {
        maps = await db.rawQuery(
            'SELECT rowid as oid, * FROM track WHERE oid NOT IN ( SELECT oid FROM track WHERE is_active = 1 ORDER BY name ASC LIMIT ' +
                offset.toString() +
                ' )ORDER BY artist ASC, name ASC LIMIT ' +
                _limit.toString());
      } else if (sortOrder == SortOrder.artist_desc) {
        maps = await db.rawQuery(
            'SELECT rowid as oid, * FROM track WHERE oid NOT IN ( SELECT oid FROM track WHERE is_active = 1 ORDER BY name ASC LIMIT ' +
                offset.toString() +
                ' )ORDER BY artist DESC, name DESC LIMIT ' +
                _limit.toString());
      } else {
        maps = await db.rawQuery(
            'SELECT rowid as oid, * FROM track WHERE oid NOT IN ( SELECT oid FROM track WHERE is_active = 1 ORDER BY oid ASC LIMIT ' +
                offset.toString() +
                ' )ORDER BY oid ASC LIMIT ' +
                _limit.toString());
      }

      List<Track> tracks = List.generate(maps.length, (i) {
        return Track(
          maps[i]['name'],
          maps[i]['id'],
          maps[i]['file_path'],
          artist: maps[i]['artist'],
          oid: maps[i]['oid'].toString(),
        );
      });

      print("fetching tracks " + tracks.length.toString());

      for (int i = 0; i < tracks.length; i++) {
        // WHAT: HOW DOES THIS EVEN WORK!!!!????
        tracks[i].oid = maps[i]['oid'].toString();

        if (maps[i]['added_date'] != null) {
          tracks[i].added_date = maps[i]['added_date'];
        }
      }
      //print("fetching trackssdfgasdgd " + maps[0]['oid'].toString());
      //print("fetching trackssdfgasdgd " + tracks[0].oid.toString());

      return tracks;
    } catch (e) {
      print(
          "AppDatabase.fetchTracksPage:fetching tracks error " + e.toString());
      return [];
    }
  } */

  //////////////////////////////////////////////////////////////////////////////

  //TODO: Test this
  static Future<Track> fetchNextTrackShuffle(
      String id, Queue<String> lastPlayed) async {
    print("fetching track shuffle " + id);
    // Get a reference to the database.
    final Database db = await (database as Future<Database>);

    String s = '';
    lastPlayed.forEach((element) => {s += element.toString() + ', '});

    if (s.isNotEmpty) {
      s = s.substring(0, s.length - 1 - 1);
    }

    print("AppDatabase.fetchNextTrackShuffle: shuffle history " + s);

    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery(
          'SELECT rowid as oid, * FROM track WHERE oid not in (' +
              s +
              ') ORDER BY RANDOM() LIMIT ' +
              '1');

      Track t = Track(
        maps[0]['name'],
        maps[0]['id'],
        maps[0]['file_path'],
        artist: maps[0]['artist'],
        oid: maps[0]['oid'].toString(),
      );
      t.oid = maps[0]['oid'].toString();
      if (maps[0]['added_date'] != null) {
        t.added_date = maps[0]['added_date'];
      }
      //*/
      //return Track("", "", "");
      return t;
    } catch (e) {
      print("fetching tracks error " + e.toString());
    }
    return Track("", "", "");
  }

  static Future<Track> fetchNextTrackShuffleFav(
      String id, Queue<String> lastPlayed) async {
    print("fetching track " + id);
    // Get a reference to the database.
    final Database db = await (database as Future<Database>);

    String s = '';
    lastPlayed.forEach((element) => {s += element.toString() + ', '});

    if (s.isNotEmpty) {
      s = s.substring(0, s.length - 1 - 1);
    }

    print("AppDatabase.fetchNextTrackShuffle: shuffle history " + s);

    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery(
          'SELECT rowid as oid, * FROM track WHERE is_active = TRUE and oid not in (' +
              s +
              ') ORDER BY RANDOM() LIMIT ' +
              '1');

      Track t = Track(
        maps[0]['name'],
        maps[0]['id'],
        maps[0]['file_path'],
        artist: maps[0]['artist'],
        oid: maps[0]['oid'].toString(),
      );
      t.oid = maps[0]['oid'].toString();
      if (maps[0]['added_date'] != null) {
        t.added_date = maps[0]['added_date'];
      }
      //*/
      //return Track("", "", "");
      return t;
    } catch (e) {
      print("fetching tracks error " + e.toString());
    }
    return Track("", "", "");
  }

  static Future<List<Track>> fetchPlaylistTracks(List<String> trackids) async {
    print("APPDB: fetching tracks");
    // Get a reference to the database.

    try {
      final Database db = await (database as Future<Database>);

      List<Track> tracks = [];

      int counter = 0;
      for (var id in trackids) {
        final List<Map<String, dynamic>> maps = await db.rawQuery(
            'SELECT rowid as oid, * FROM track WHERE id = \'' + id + '\'');
        Track t = Track(
          maps[0]['name'],
          maps[0]['id'].toString(),
          maps[0]['file_path'],
          artist: maps[0]['artist'],
        );
        t.oid = maps[0]['oid'].toString();
        if (maps[0]['added_date'] != null) {
          t.added_date = maps[0]['added_date'];
        }
        t.playlist_index = counter;
        tracks.add(t);
        counter++;
      }

      return tracks;
    } catch (e) {
      print("AppDatabase.fetchPlaylistTracks:" + e.toString());
      return [];
    }
  }

  static void favourite(Track t) async {
    print("AppDatabase.favourite:");
    try {
      final Database db = await (database as Future<Database>);
      // Query the table
      int count = await db.update('track', {'is_active': 1},
          where: 'rowid = ?', whereArgs: [t.oid]);

      //print("AppDatabase.fetchTracksPage: Error " + maps[0].toString());
    } catch (e) {
      print("AppDatabase.favourite: Error " + e.toString());
    }
  }

  static void unfavourite(Track t) async {
    print("AppDatabase.unfavourite:");
    try {
      final Database db = await (database as Future<Database>);
      // Query the table
      int count = await db.update('track', {'is_active': 0},
          where: 'rowid = ?', whereArgs: [t.oid]);

      print("AppDatabase.unfavourite: Updated " + count.toString());
    } catch (e) {
      print("AppDatabase.unfavourite: Error " + e.toString());
    }
  }

  /*
  Future<void> updateDog(Dog dog) async {
    // Get a reference to the database.
    final db = await database;

    // Update the given Dog.
    await db.update(
      'dogs',
      dog.toMap(),
      // Ensure that the Dog has a matching id.
      where: 'id = ?',
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [dog.id],
    );
  }

  Future<void> deleteDog(int id) async {
    // Get a reference to the database.
    final db = await database;

    // Remove the Dog from the database.
    await db.delete(
      'dogs',
      // Use a `where` clause to delete a specific dog.
      where: 'id = ?',
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }
  */
}
