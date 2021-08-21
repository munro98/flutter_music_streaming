import 'dart:async';
import 'dart:convert' show json, utf8;
import 'dart:io';

import 'package:http/http.dart' as http;

class Playlist {
  Playlist(String this.name, String this.id);
  
  //bool downloaded
  String name;
  String id;


  DateTime? created_date;
  DateTime? last_modified_date;
  DateTime? last_played_date;
  double? duration;
  int? size;
}
