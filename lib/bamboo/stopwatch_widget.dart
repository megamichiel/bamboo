import 'dart:async';
import 'dart:ui';

import 'package:bamboo/main.dart';
import 'package:flutter/material.dart';

class StopwatchWidget extends StatefulWidget {
  const StopwatchWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StopwatchState();
}

class StopwatchState extends State<StopwatchWidget> {
  int passedTime = 0, timeOffset = 0;

  Timer? timer;
  bool timerRunning = false;

  startTimer() {
    var startTime = DateTime.now();

    timer = Timer.periodic(const Duration(milliseconds: 10), (t) {
      if (timerRunning) {
        setState(() {
          passedTime = timeOffset +
              DateTime.now().difference(startTime).inMilliseconds ~/ 10;
        });
      }
    });
    timerRunning = true;
  }

  stopTimer() {
    timer?.cancel();
    timerRunning = false;
    timeOffset = passedTime;
  }

  clearTimer() {
    setState(() {
      passedTime = timeOffset = 0;
    });
  }

  @override
  dispose() {
    timer?.cancel();
    timerRunning = false;

    super.dispose();
  }

  Widget createTimerText(String text, TextTheme theme, Color color) {
    return Text(
      text,
      style: theme.headline2?.merge(TextStyle(
          color: color, fontFeatures: const [FontFeature.tabularFigures()])),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextTheme theme = Theme.of(context).textTheme;

    var centiSeconds = passedTime;

    var seconds = centiSeconds ~/ 100;
    var minutes = seconds ~/ 60;
    var hours = minutes ~/ 60;

    centiSeconds -= seconds * 100;
    seconds -= minutes * 60;
    minutes -= hours * 60;

    pad(int i) => i.toString().padLeft(2, '0');

    return Padding(
      padding:
          EdgeInsets.fromLTRB(0, 0, 0, (theme.headline2?.fontSize ?? 0) / 2),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Padding(
          padding: EdgeInsets.all((theme.headline2?.fontSize ?? 0) / 2),
          child: createTimerText(
              "${hours == 0 ? minutes.toString() : ('$hours:${pad(minutes)}')}:${pad(seconds)}:${pad(centiSeconds)}",
              theme,
              Colors.black),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    0, (theme.headline3?.fontSize ?? 0) / 4, 0, 0),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      if (timerRunning) {
                        // TODO checkpoints
                      } else {
                        clearTimer();
                      }
                    });
                  },
                  child: Padding(
                    padding:
                        EdgeInsets.all((theme.headline3?.fontSize ?? 0) / 4),
                    child: Icon(
                        timerRunning
                            ? Icons.outlined_flag_rounded
                            : Icons.refresh,
                        color: Colors.black),
                  ),
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    0, (theme.headline3?.fontSize ?? 0) / 4, 0, 0),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(200)),
                  color: primaryColor,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        if (timerRunning) {
                          stopTimer();
                        } else {
                          startTimer();
                        }
                      });
                    },
                    child: Padding(
                      padding:
                          EdgeInsets.all((theme.headline3?.fontSize ?? 0) / 4),
                      child: Icon(timerRunning ? Icons.pause : Icons.play_arrow,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      ]),
    );
  }
}
