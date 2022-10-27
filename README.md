# Flutter Music Streaming App

Writing a cross platform streaming music player in flutter.

A music streaming app for desktop and mobile that connects to a Nodejs, Expressjs, MongoDB server and caches music locally.

This turned out to be a lot more complicated than I though since no packages support everything on all platforms. I need audio playing, file downloading, a database, filesystem access on Android/Mac/IOS/Windows and Linux while also wrangling permissions on mobile.

Currently only android is working and windows is partially working so a lot more work to be done.

## Dependecies
- Audio assets player (Playback on Android/IOS/Mac)
- dart_vlc (Playback on Windows/Linux)
- flutter_downloader (Downloading on Android)
- sqflite_common_ffi(Database on Android/Mac/IOS/Windows/Linux)
- scrollable_positioned_list (Flexible alternative to ListView)
- path_provider (For finding directories)

