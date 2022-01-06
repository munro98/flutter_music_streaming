import 'dart:collection';
import 'dart:math';

import 'package:flutter_music_app/AppDatabase.dart';
import 'package:path/path.dart';

import 'Track.dart';

import 'AppDatabase.dart';
import 'API.dart';
import 'Playlist.dart';


enum PlayContext {
  all,
  playlist
}

enum LoopMode {
  none,
  one,
  all
}

class Player {

  //static int THREASH = 512;

  Player();

  //Track current;
  Track ? current;
  int current_ind = 0;

  //List<Playlist> playlists
  //Playlist currentSelected

  PlayContext _vs = PlayContext.all;

  List < Track > _tracks = [];
  List < Track > shuffle_tracks = [];

  bool isLooping = false;
  bool isShuffle = false;

  //bool isLargePlaylist = false;
  //DoubleLinkedQueue < int > queue; // 128 max length
  //Set < int > set;

  void loadPlaylist(Playlist playlist) async {

    if (playlist.id == "#ALL#") {
      
      /*
      final tracks2 = await AppDatabase.fetchTracks();
      
      setState(() {
      _vs = ViewState.all;
      _tracks = tracks2;
      _pagingController.refresh();
    });
    */
      
    } else {
      final tracksids = await Api.fetchPlaylistsTracks(playlist.id);
      final tracks2 = await AppDatabase.fetchPlaylistTracks(tracksids);//fetchTracksByPlaylist

      //setState(() {
      _vs = PlayContext.playlist;
      _tracks = tracks2;
      //_pagingController.refresh();
    //});
      
    }
  }

  void toggleShuffle() {
    isShuffle = !isShuffle;

    if (isShuffle) {
      //if (tracks.length < THREASH) {
        current_ind = 0;
        shuffle_tracks = _tracks;
        shuffle_tracks.shuffle();
      //  isLargePlaylist = false;

      //} else {
      //  isLargePlaylist = true;
      //}
    }
  }

  Future < Track > getNextTrack() async {

    if (current != null) {

      if (_vs == PlayContext.all) {

        Track c = current as Track;
        print(" ________________________________________________________________________________________________________________________oid " + c.oid.toString());

        Track next = await AppDatabase.fetchNextTrack(c.oid as String, "");
        print("________________________________________" + next.name);
        return next;

      } else if (_vs == PlayContext.playlist) {

        if (isShuffle) {

          //if (!isLargePlaylist) {

            var t = shuffle_tracks[current_ind];
            current_ind = current_ind+1 % shuffle_tracks.length;
            return t;
          /*
          } else {

            var rng = new Random();
            int new_ind = rng.nextInt(tracks.length);

            int i = 0;
            while (i < 4) {
              if (!set.contains(new_ind)) {
                break;
              }
              new_ind = rng.nextInt(tracks.length);

            }

            if (queue.length == 128) {

              int front = queue.iterator.current;
              queue.removeFirst();
              set.remove(front);

              queue.addLast(new_ind);

            }

            return tracks[new_ind];
          }
          */

        }
      }

    }
    throw Exception();
  }

  Future < Track > getPrevTrack() async {

    if (current != null) {

      if (_vs == PlayContext.all) {

        if (current != null) {
          Track c = current as Track;
          Track next = await AppDatabase.fetchPrevTrack(c.oid as String, "");
          return next;
        }

      } else if (_vs == PlayContext.playlist) {

        int ind = current_ind-1;
        if (ind < 0) {
          ind = shuffle_tracks.length -1;
        }

        var t = shuffle_tracks[ind];
        current_ind = ind;
        return t;

      }
    }
    throw Exception();
  }

}