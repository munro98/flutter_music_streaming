import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:assets_audio_player/assets_audio_player.dart' hide Playlist;
import 'dart:ui';

import 'MainRoute.dart';

/// This is the stateful widget that the main application instantiates.
class SeekBar extends StatefulWidget {
  const SeekBar(this.crt, {Key? key}) : super(key: key);

  final MainRouteState crt;

  @override
  State<SeekBar> createState() => SeekBarState(crt);
}

/// This is the private State class that goes with SeekBar.
/// AnimationControllers can be created with `vsync: this` because of TickerProviderStateMixin.
class SeekBarState extends State<SeekBar> with TickerProviderStateMixin {
  //late AnimationController controller;

  final MainRouteState crt;
  double progressValue = 0.0;

  SeekBarState(this.crt);

  /*
  void reset() {
    controller.reset();
  }

  void stop() {
    controller.stop();
  }

  void resume() {
    controller.forward(from: controller.value);
  }
  */

  void setProgressValue(double val) {
    this.setState(() {
      //controller.value = val;
    });
    //controller.forward(from: val);
  }

  void setProgressDuration(Duration duration) {
    /*
    this.setState(() {
      var a = ((duration.inMilliseconds as double) /
          (controller.duration?.inMilliseconds as double)) as double;
      controller.value = a;
    });
    */
  }

  void setDurationValue(Duration duration) {
    /*
    this.setState(() {
      controller.duration = duration;
    });
    */
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    //controller.dispose();
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
          Slider(
            value: progressValue,
            min: 0,
            max: 1,
            //divisions: 5,
            //label: progressValue.round().toString(),
            onChanged: (double value) {
              setState(() {
                progressValue = value;
              });
            },
          )
        ],
      ),
    );
  }
}
