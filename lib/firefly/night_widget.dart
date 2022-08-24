import 'package:bamboo/android_caller.dart';
import 'package:bamboo/widget.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class NightWidget extends BackButtonWidget<String> {
  const NightWidget(super.backContext, super.backId, {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => NightState();
}

const maxDarkness = 220;

class NightState extends BackButtonState<NightWidget> {
  var brightness = maxDarkness.toDouble();

  @override
  bool onBackPressed() {
    return false;
  }

  @override
  void initState() {
    super.initState();

    AndroidCaller.getNight().then((value) => {
          setState(() {
            brightness = (maxDarkness - value).toDouble();
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        createPaddedIcon(
            Icons.nightlight_round, Colors.white, screenWidth / 6, () {},
            background: primaryColor),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: FractionallySizedBox(
                widthFactor: 0.75,
                child: Card(
                  child: Slider(
                    min: 0,
                    max: maxDarkness.toDouble(),
                    divisions: maxDarkness + 1,
                    value: brightness,
                    onChanged: (v) {
                      setState(() {
                        brightness = v;
                        AndroidCaller.setNight((maxDarkness - v).round());
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
