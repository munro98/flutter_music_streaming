import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'Track.dart';

class AppDatabase {
  static Future<Database>? database;
/*
  AppDatabase(
  ) {
    database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'music_lib.db'),
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          "CREATE TABLE track(id INTEGER PRIMARY KEY, name TEXT, age INTEGE)",
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }
  */

  static Future<void> openConnection() async {
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

    // "CREATE TABLE playlist(id BINARY(12) PRIMARY KEY, name TEXT, description TEXT, created_at TEXT, store_locally BOOL)"
    // // "CREATE TABLE playlist_item(id BINARY(12) PRIMARY KEY, track_id BINARY(12), is_active BOOL, added_at TEXT)"
  }

  static Future<void> insertTrack(Track track) async {
    // Get a reference to the database.
    final Database db = await (database as Future<Database>);

    // In this case, replace any previous data.
    await db.insert(
      'track',
      track.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static void syncDatabase() async {}

  static Future<List<Track>> fetchTracks() async {
    print("AppDatabase: fetchTracks()");
    // Get a reference to the database.

    try {
      final Database db = await (database as Future<Database>);

      // Query the table
      final List<Map<String, dynamic>> maps = await db.query('track');

      List<Track> tracks = List.generate(maps.length, (i) {
        return Track(
          maps[i]['name'],
          maps[i]['id'],
          maps[i]['file_path'],
          artist: maps[i]['artist'],
        );
      });

      return tracks;
    } catch (e) {
      return [];
    }
  }

  static Future<List<Track>> fetchTracksPage(int _limit, int offset) async {
    try {
      print("AppDatabase: fetchTracksPage(int _limit, int offset)");
      // Get a reference to the database.
      final Database db = await (database as Future<Database>);

      // Query the table
      //final List<Map<String, dynamic>> maps = await db.query('track', where: 'rowid > ?', whereArgs: [id],
      //orderBy: 'rowid', limit: _limit);
      //final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT * FROM track WHERE rowid NOT IN ( SELECT rowid FROM track ORDER BY rowid ASC LIMIT 50 ) ORDER BY rowid ASC LIMIT 10');

      /*
      // https://gist.github.com/ssokolow/262503
      final List<Map<String, dynamic>> maps = await db.rawQuery(
          'SELECT rowid as oid, * FROM track WHERE oid NOT IN ( SELECT oid FROM track ORDER BY oid ASC LIMIT ' +
              offset.toString() +
              ' )ORDER BY oid ASC LIMIT ' +
              _limit.toString());
      */
      final List<Map<String, dynamic>> maps = await db.rawQuery(
          'SELECT rowid as oid, * FROM track WHERE oid NOT IN ( SELECT oid FROM track ORDER BY name ASC LIMIT ' +
              offset.toString() +
              ' )ORDER BY name ASC LIMIT ' +
              _limit.toString());

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
        // TODO: HOW DOES THIS EVEN WORK!!!!????
        tracks[i].oid = maps[i]['oid'].toString();
      }
      print("fetching trackssdfgasdgd " + maps[0]['oid'].toString());
      print("fetching trackssdfgasdgd " + tracks[0].oid.toString());

      return tracks;
    } catch (e) {
      print("fetching tracks error " + e.toString());
      return [];
    }
  }

  static Future<Track> fetchTrack(int id) async {
    print("APPDB: fetchtrack");
    // Get a reference to the database.
    final Database db = await (database as Future<Database>);

    // Query the table
    final List<Map<String, dynamic>> maps =
        await db.query('track', where: 'rowid = ?', whereArgs: [id]);

    return Track(
      maps[0]['name'],
      maps[0]['id'],
      maps[0]['file_path'],
      artist: maps[0]['artist'],
    );
  }

  static Future<Track> fetchNextTrack(String id, String sortOrder) async {
    print("fetching track " + id);
    // Get a reference to the database.
    final Database db = await (database as Future<Database>);

    //final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT rowid as oid, * FROM track WHERE oid > '+ id + ' ORDER BY oid ASC LIMIT ' + '1');

    try {
      // get name off track
      final List<Map<String, dynamic>> maps1 = await db.rawQuery(
          'SELECT rowid as oid, ROW_NUMBER() OVER(ORDER BY name) AS noid, * FROM track WHERE oid = ' +
              id);

      String findName = maps1[0]['name'];
      int findId = maps1[0]['oid'];

      /*
      if ( findName == maps[0]['name']) {
         db.rawQuery( id > findID & name >=
      } else {
        db.rawQuery( name >= 
      }

      SELECT rowid as oid, * FROM track WHERE (name >= findName) and ((name LIKE findName and id > findID ) or (name NOT LIKE findName))

      */
      ///*
      ///
      /*
      // get first track with same name or after alphabetically and also with id occuring later in the DB
      final List<Map<String, dynamic>> maps = await db.rawQuery(
          'SELECT rowid as oid, ROW_NUMBER() OVER(ORDER BY name) AS noid, * FROM track WHERE oid != ' +
              id +
              ' AND name >= \'' +
              findName +
              '\' ORDER BY name ASC LIMIT ' +
              '1');
      */
      final List<Map<String, dynamic>> maps = await db.rawQuery(
          'SELECT rowid as oid, * FROM track WHERE ' +
              '(name LIKE \'' +
              findName +
              '\' and oid > ' +
              findId.toString() +
              ' ) or (name > \'' +
              findName +
              '\' ) ORDER BY name ASC LIMIT ' +
              '1');

      Track t = Track(
        maps[0]['name'],
        maps[0]['id'],
        maps[0]['file_path'],
        artist: maps[0]['artist'],
        oid: maps[0]['oid'].toString(),
      );
      t.oid = maps[0]['oid'].toString();
      //*/
      //return Track("", "", "");
      return t;
    } catch (e) {
      print("fetching tracks error " + e.toString());
    }
    return Track("", "", "");
  }

  static Future<Track> fetchPrevTrack(String id, String sortOrder) async {
    print("APPDB: fetchPrevTrack");
    // Get a reference to the database.
    final Database db = await (database as Future<Database>);

    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT rowid as oid, * FROM track WHERE oid < ' +
            id +
            ' ORDER BY oid DESC LIMIT ' +
            '1');

    Track t = Track(
      maps[0]['name'],
      maps[0]['id'],
      maps[0]['file_path'],
      artist: maps[0]['artist'],
      oid: maps[0]['oid'].toString(),
    );
    t.oid = maps[0]['oid'].toString();

    return t;
  }

  static Future<List<Track>> fetchPlaylistTracks(List<String> trackids) async {
    print("APPDB: fetching tracks");
    // Get a reference to the database.

    try {
      final Database db = await (database as Future<Database>);

      List<Track> tracks = [];

      for (var id in trackids) {
        final List<Map<String, dynamic>> maps =
            await db.rawQuery('SELECT * FROM track WHERE id = \'' + id + '\'');
        tracks.add(Track(
          maps[0]['name'],
          maps[0]['id'],
          maps[0]['file_path'],
          artist: maps[0]['artist'],
        ));
      }

      return tracks;
    } catch (e) {
      return [];
    }
  }

  /*
  static Future<List<Track>> fetchPlaylistTracksPage (String id ,int _limit, int offset) async {
    try {
      print("fetching tracks");
      // Get a reference to the database.
      //final Database db = await (database as Future<Database>);

      //final List<Map<String, dynamic>> maps = await db.rawQuery(
      //  'SELECT track.name, track,id, track.file_path FROM track WHERE oid NOT IN ( SELECT oid FROM track ORDER BY oid ASC LIMIT ' + offset.toString() + ' )ORDER BY oid ASC LIMIT ' + _limit.toString());
      //'SELECT track.name, track,id, track.file_path FROM track INNER JOIN  WHERE oid NOT IN ( SELECT oid FROM track ORDER BY oid ASC LIMIT ' + offset.toString() + ' )ORDER BY oid ASC LIMIT ' + _limit.toString()

      List<Track> tracks = List.generate(maps.length, (i) {
        return Track(
          maps[i]['name'],
          maps[i]['id'],
          maps[i]['file_path'],
          artist: maps[i]['artist'],
        );
      });

      print("fetching tracks " + tracks.length.toString());

      return tracks;
    } catch (e) {
      return [];
    }
  }

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
