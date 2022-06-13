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

  void resume() {
    controller.forward(from: controller.value);
  }

  void setProgressValue(double val) {
    this.setState(() {
      controller.value = val;
    });
    controller.forward(from: val);
  }

  void setProgressDuration(Duration duration) {
    this.setState(() {
      var a = ((duration.inMilliseconds as double) /
          (controller.duration?.inMilliseconds as double)) as double;
      controller.value = a;
    });
  }

  void setDurationValue(Duration duration) {
    this.setState(() {
      controller.duration = duration;
    });
  }

  void setRepeat(Duration duration) {
    //_beginOffset = _endOffset;
    //_endOffset = _endOffset + _animationOffset;

    setState(() {
      //_characterPosition = _generateCharacterPosition();
      controller.value = 0.5;
    });
    //controller.reset();
    //controller.duration = const Duration(seconds: 120);
    //controller.repeat(min: 0, max: 1, reverse: false);
    controller.forward(from: 0.5);
    //initState();
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
    controller.repeat(min: 0, max: 1, reverse: false);
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
