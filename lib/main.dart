import 'package:bamboo/android_caller.dart';
import 'package:bamboo/firefly/firefly.dart';
import 'package:flutter/material.dart';

import 'bamboo/bamboo.dart';

void main(List<String> args) {
  switch (args[0]) {
    case "bamboo":
      runApp(const BambooApp());
      break;
    case "firefly":
      print("Args are $args");
      runApp(args.length >= 2
          ? FireflyApp(args[1])
          : const FireflyApp(null));
      break;
  }
}

const primaryColor = Colors.green,
    accentColor = Colors.blue,
    backgroundColor = Colors.black;

const cardElevation = 8.0;
const cardRadius = 20.0;

const animationTime = Duration(milliseconds: 150);

Widget createPaddedIcon(
    IconData icon, Color color, double width, void Function() clickAction,
    {Color? background}) {
  return AnimatedPadding(
    duration: animationTime,
    padding: EdgeInsets.all(width / 8),
    child: Card(
      color: background,
      child: TextButton(
        onPressed: clickAction,
        child: AnimatedSize(
          duration: animationTime,
          child: SizedBox(
            width: width,
            child: AnimatedPadding(
              duration: animationTime,
              padding: EdgeInsets.all(width / 5),
              child:
                  FittedBox(fit: BoxFit.fill, child: Icon(icon, color: color)),
            ),
          ),
        ),
      ),
    ),
  );
}

abstract class BaseApp extends StatelessWidget {
  final String title;

  const BaseApp(this.title, {Key? key}) : super(key: key);

  Widget buildWidget(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firefly',
      theme: ThemeData(
          primarySwatch: accentColor,
          scaffoldBackgroundColor: Colors.transparent,
          cardTheme: CardTheme(
              elevation: cardElevation,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cardRadius))),
          buttonTheme: ButtonThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cardRadius)))),
      home: buildWidget(context),
    );
  }
}

abstract class RootWidgetState<W extends StatefulWidget> extends State<W> {
  var _launching = true, _exiting = false;

  void exit() {
    setState(() {
      _exiting = true;
    });
  }

  Widget buildRootWidget(Widget content) {
    var widget = GestureDetector(
      onTap: exit,
      child: AnimatedContainer(
        duration: animationTime,
        color: backgroundColor.withAlpha(_exiting ? 0 : 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: animationTime,
              scale: _exiting ? 0 : 1,
              onEnd: AndroidCaller.exit,
              child: content,
            ),
          ],
        ),
      ),
    );

    if (_launching) {
      setState(() {
        _launching = false;
      });
    }

    return widget;
  }
}
