import 'package:bamboo/firefly/night_widget.dart';
import 'package:bamboo/widget.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'light_list_widget.dart';

class FireflyApp extends BaseApp {
  const FireflyApp(String? arg, {Key? key})
      : initialState = "night" == arg ? 1 : 0,
        super("Firefly", key: key);

  final int initialState;

  @override
  Widget buildWidget(BuildContext context) {
    return FireflyWidget(initialState);
  }
}

class FireflyWidget extends StatefulWidget {
  const FireflyWidget(this.initialState, {Key? key}) : super(key: key);

  final int initialState;

  @override
  State<StatefulWidget> createState() => _FireflyState();
}

class _FireflyState extends RootWidgetState<FireflyWidget> {
  // 0 = nothing, 1 = night, 2 = light
  late int state = widget.initialState;

  final BackContext<String> backContext = {};

  void Function() stateButton(int state) {
    return () {
      setState(() {
        this.state = this.state == state ? 0 : state;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    return buildRootWidget(BackButtonProvider<String>(
      backContext,
      () {
        return (const [null, "night", "light"])[state];
      },
      defaultAction: (hasState) {
        if (hasState) {
          setState(() {
            state = 0;
          });
        } else {
          exit();
        }
      },
      child: GestureDetector(
        onTap: () {},
        child: AnimatedCrossFade(
          firstChild: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              createPaddedIcon(Icons.nightlight, Colors.black,
                  screenWidth / 5, stateButton(1)),
              createPaddedIcon(Icons.light_mode, Colors.black, screenWidth / 5,
                  stateButton(2)),
            ],
          ),
          secondChild: state == 1
              ? NightWidget(backContext, "night")
              : LightListWidget(backContext, "light"),
          crossFadeState:
              state == 0 ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: animationTime,
        ),
      ),
    ));
  }
}
