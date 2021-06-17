import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

//import 'package:flutter/widgets.dart'

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

  static void openConnection() async {

    database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'music_lib.db'),
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          //"CREATE TABLE track(id BINARY(12) PRIMARY KEY, name TEXT, file_path TEXT, artist TEXT)",
          "CREATE TABLE track(id BINARY(12) PRIMARY KEY, name TEXT, file_path TEXT, artist TEXT, release_date TEXT, added_date TEXT, last_played_date TEXT, year INT, genre TEXT, artists TEXT, is_active BOOL, is_missing BOOL, is_downloaded BOOL, play_count INT, track INT, track_of INT, disk INT, disk_of INT, album TEXT, duration INT, size INT, format TEXT)",
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );

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

  static void syncDatabase() async {
  }

  static Future<List<Track>> fetchTracks () async {

    print("fetching tracks");
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

    } catch(e) {
      return [];
    }
    
  }

  static Future<List<Track>> fetchTracksPage (int _limit, int offset) async {
    try {
      print("fetching tracks");
      // Get a reference to the database.
      final Database db = await (database as Future<Database>);


      // Query the table
      //final List<Map<String, dynamic>> maps = await db.query('track', where: 'rowid > ?', whereArgs: [id],
      //orderBy: 'rowid', limit: _limit);
      //final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT * FROM track WHERE rowid NOT IN ( SELECT rowid FROM track ORDER BY rowid ASC LIMIT 50 ) ORDER BY rowid ASC LIMIT 10');

      // https://gist.github.com/ssokolow/262503
      final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT * FROM track WHERE oid NOT IN ( SELECT oid FROM track ORDER BY oid ASC LIMIT ' + offset.toString() + ' )ORDER BY oid ASC LIMIT ' + _limit.toString());

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

  static Future<Track> fetchTrack (int id) async {

    print("fetching track");
    // Get a reference to the database.
    final Database db = await (database as Future<Database>);

    // Query the table
    final List<Map<String, dynamic>> maps = await db.query('track', where: 'rowid = ?', whereArgs: [id]);

    return Track(
      maps[0]['name'],
      maps[0]['id'],
      maps[0]['file_path'],
      artist: maps[0]['artist'],
    );



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