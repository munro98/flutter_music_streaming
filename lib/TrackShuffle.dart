import 'dart:collection';

import 'Track.dart';

class TrackShuffle {

  static int threash = 512;
  static int memory = 128;

  List<String> ids = List<String>[];
  int curr = 0;

  // max size track_memory
  DoubleLinkedQueue<> dq;
  Map<String, > map;

  void initTracks(List<Track> t) {
    ids.clear();
    for (int i = 0; i < t.length; i++) {
      ids.add(t[i].id);
    }
    ids.shuffle();
    curr = 0;

  }

  int nextTrack(List<Track> t) {
    ids.clear();
    for (int i = 0; i < t.length; i++) {
      ids.add(t[i].id);
    }
  }

  int nextTrack2() {

    map.push_back(id, currentTrack);
    dq.add(id, currentTrack);

    if (map.length >= memory) {
      remove =  map.pop_front();
      map.remove(remove);
    }

    int i = 0;
    while(i < 4) {
      nextTrack = random.int(0, playlist.length);
      if (!map.contains(track[nextTrack]) {
        return track[nextTrack];
      } 
    }
    nextTrack = random.int(0, playlist.length);
    return track[nextTrack];

  }


}