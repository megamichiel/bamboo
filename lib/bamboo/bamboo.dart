import 'package:flutter/material.dart';

import '../android_caller.dart';
import '../main.dart';
import 'stopwatch_widget.dart';
import 'timer_widget.dart';

class BambooApp extends BaseApp {
  const BambooApp({Key? key}) : super("Bamboo", key: key);

  @override
  Widget buildWidget(BuildContext context) {
    return const BambooWidget();
  }
}

class BambooWidget extends StatefulWidget {
  const BambooWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BambooState();
}

class _BambooState extends RootWidgetState {
  // 0 = nothing, 1 = timer, 2 = stopwatch
  int state = 0;

  final _animatedListKey = GlobalKey<AnimatedListState>();

  void Function() stateButton(int state, timerWidget, stopwatchWidget) {
    return () {
      setState(() {
        var prevState = this.state;
        this.state = this.state == state ? 0 : state;
        if (this.state == 0 && prevState != 0) {
          _animatedListKey.currentState?.removeItem(
              1,
              (context, animation) => SizeTransition(
                    sizeFactor: animation,
                    child: AnimatedCrossFade(
                      firstChild: timerWidget,
                      secondChild: stopwatchWidget,
                      crossFadeState: prevState == 1
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: animationTime,
                    ),
                  ),
              duration: animationTime);
        } else if (this.state != 0 && prevState == 0) {
          _animatedListKey.currentState?.insertItem(1, duration: animationTime);
        }
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    var timerWidget =
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {},
            child: Card(
              child: TimerWidget((s) {
                var m = s ~/ 60;
                var h = m ~/ 60;

                s -= m * 60;
                m -= h * 60;

                pad(int i) => i.toString().padLeft(2, '0');

                String text;

                if (h == 0) {
                  text = m == 0 ? "$s seconds" : "$m:${pad(s)}";
                } else {
                  text = "$h:${pad(m)}:${pad(s)}";
                }

                AndroidCaller.toast("Timer set for $text");

                exit();
              }),
            ),
          )
        ],
      ),
    ]);

    var stopwatchWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {},
              child: const Card(
                child: StopwatchWidget(),
              ),
            )
          ],
        ),
      ],
    );

    return buildRootWidget(WillPopScope(
      onWillPop: () async {
        exit();

        return false;
      },
      child: AnimatedList(
          shrinkWrap: true,
          key: _animatedListKey,
          initialItemCount: state == 0 ? 1 : 2,
          itemBuilder: (context, index, animation) {
            var screenWidth = MediaQuery.of(context).size.width;
            return index == 0
                ? Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    createPaddedIcon(
                        Icons.hourglass_bottom,
                        state == 1 ? primaryColor : Colors.black,
                        screenWidth / (state == 2 ? 6 : 5),
                        stateButton(1, timerWidget, stopwatchWidget)),
                    createPaddedIcon(
                        Icons.timer,
                        state == 2 ? primaryColor : Colors.black,
                        screenWidth / (state == 1 ? 6 : 5),
                        stateButton(2, timerWidget, stopwatchWidget)),
                  ])
                : SizeTransition(
                    sizeFactor: animation,
                    child: AnimatedCrossFade(
                        firstChild: timerWidget,
                        secondChild: stopwatchWidget,
                        crossFadeState: state == 1
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: animationTime),
                  );
          }),
    ));
  }
}
