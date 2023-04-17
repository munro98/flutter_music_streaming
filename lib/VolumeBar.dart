import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:assets_audio_player/assets_audio_player.dart' hide Playlist;
import 'dart:ui';

import 'MainRoute.dart';

/// This is the stateful widget that the main application instantiates.
class VolumeBar extends StatefulWidget {
  const VolumeBar(this.crt, {Key? key}) : super(key: key);

  final MainRouteState crt;

  @override
  State<VolumeBar> createState() => VolumeBarState(crt);
}

/// This is the private State class that goes with VolumeBar.
/// AnimationControllers can be created with `vsync: this` because of TickerProviderStateMixin.
class VolumeBarState extends State<VolumeBar> with TickerProviderStateMixin {
  //late AnimationController controller;

  final MainRouteState crt;
  double progressValue = 1.0;
  VolumeBarState(this.crt);

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
      padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
      child: Column(
        //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SliderTheme(
              data: SliderThemeData(
                  trackHeight: 8,
                  trackShape: CustomTrackShape(),
                  overlayShape: SliderComponentShape.noOverlay),
              child: Slider(
                value: progressValue,
                min: 0,
                max: 1,
                //divisions: 5,
                //label: progressValue.round().toString(),
                onChanged: (double value) {
                  crt.vol(value);
                  setState(() {
                    progressValue = value;
                  });
                },
              ))
        ],
      ),
    );
  }

  void setValue(double fraction) {
    if (fraction.isNaN) return;
    setState(() {
      progressValue = fraction;
    });
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double? trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
