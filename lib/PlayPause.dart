import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'MainRoute.dart';

class PlayPause extends StatefulWidget {
  const PlayPause(this.crt, {Key? key}) : super(key: key);

  final MainRouteState crt;

  @override
  State<PlayPause> createState() => PlayPauseState(crt);
}

class PlayPauseState extends State<PlayPause> with TickerProviderStateMixin {
  late AnimationController controller;

  final MainRouteState crt;
  late bool targetState;
  late bool currentState;

  PlayPauseState(this.crt);

  void reset() {
    controller.reset();
  }

  void setTargetState(bool b) {
    this.targetState = b;
    controller.reset();
  }

  @override
  void initState() {
    controller = AnimationController(
      /// [AnimationController]s can be created with `vsync: this` because of
      /// [TickerProviderStateMixin].
      vsync: this,
      duration: const Duration(milliseconds: 10),
    )..addListener(() {
        print("PlayPause: currentState = targetState;");
        setState(() {
          currentState = targetState;
        });
      });
    controller.repeat(reverse: false);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        controller.isAnimating
            ? new Icon(Icons.play_arrow)
            : new Icon(Icons.pause)
      ],
    );
  }
}
