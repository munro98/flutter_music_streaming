import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:assets_audio_player/assets_audio_player.dart' hide Playlist;
import 'dart:ui';

import 'CategoryRoute.dart';

/// This is the stateful widget that the main application instantiates.
class SeekBar extends StatefulWidget {
  const SeekBar(this.crt, {Key? key}) : super(key: key);

  final CategoryRouteState crt;

  @override
  State<SeekBar> createState() => SeekBarState(crt);
}

/// This is the private State class that goes with SeekBar.
/// AnimationControllers can be created with `vsync: this` because of TickerProviderStateMixin.
class SeekBarState extends State<SeekBar> with TickerProviderStateMixin {
  late AnimationController controller;

  final CategoryRouteState crt;
  double progressBarValue = 0.0;

  SeekBarState(this.crt);

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
