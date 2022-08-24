import 'dart:ui';

import 'package:flutter/material.dart';

import '../android_caller.dart';
import '../main.dart';

class TimerWidget extends StatefulWidget {
  final void Function(int) onTimeSelected;

  const TimerWidget(this.onTimeSelected, {super.key});

  @override
  State<StatefulWidget> createState() => TimerState();
}

class TimerState extends State<TimerWidget> {
  // States are [0 = all, 1 = seconds, 2 = minutes, 3 = hour)
  int activeCursor = 0;
  List<int> cursors = [0, 0, 0];

  // Digits from right to left (seconds -> minutes -> hours)
  List<int> digits = [0, 0, 0, 0, 0, 0];

  startTimer(int length) async {
    await AndroidCaller.startTimer(length);

    widget.onTimeSelected(length);
  }

  Widget createDigitButton(
      Widget widget, void Function()? action, TextTheme theme) {
    return TextButton(
        onPressed: action,
        child: SizedBox(
          height: (theme.headline4?.fontSize ?? 0) * 1.5,
          child: AspectRatio(aspectRatio: 1, child: Center(child: widget)),
        ));
  }

  Widget createDigitTextButton(
      String text, void Function()? action, TextTheme theme) {
    return createDigitButton(
      Text(text,
          style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontFeatures: [FontFeature.tabularFigures()])
              .merge(theme.headline4)),
      action,
      theme,
    );
  }

  Widget createTimerText(
      String text, Color? color, void Function()? action, TextTheme theme) {
    Widget result = Text(text,
        style: theme.headline2?.merge(TextStyle(
            color: color, fontFeatures: const [FontFeature.tabularFigures()])));
    return action != null
        ? GestureDetector(onTap: action, child: result)
        : result;
  }

  Color? getTextColor(int index, Color? primary, Color? secondary) {
    return activeCursor == 0
        ? primaryColor
        : index == activeCursor - 1
            ? primary
            : secondary;
  }

  void Function() timeButton(int index) {
    return () {
      setState(() {
        activeCursor = index + 1;
      });
    };
  }

  void Function() pressDigit(int value) {
    return () {
      setState(() {
        var cursor = cursors[activeCursor == 0 ? 0 : activeCursor - 1];

        if (cursor == 0 && value == 0) {
          return;
        }

        int cursorIndex = activeCursor, startDigit;
        if (cursorIndex == 0) {
          while (cursorIndex < 2 && cursor == 2) {
            cursor = cursors[++cursorIndex];
          }
          startDigit = 0;
        } else {
          startDigit = (--cursorIndex) * 2;
        }

        if (cursor < 2) {
          for (var index = cursorIndex * 2 + cursor - 1;
              index >= startDigit;
              --index) {
            digits[index + 1] = digits[index];
          }
          digits[startDigit] = value;

          cursors[cursorIndex]++;
        }
      });
    };
  }

  void Function() backspace() {
    return () {
      setState(() {
        var cursor = cursors[activeCursor == 0 ? 0 : activeCursor - 1];

        int cursorIndex = activeCursor, startDigit, endDigit;
        if (cursorIndex == 0) {
          while (
              cursorIndex < 2 && cursor == 2 && cursors[cursorIndex + 1] > 0) {
            cursor = cursors[++cursorIndex];
          }
          startDigit = 0;
        } else {
          startDigit = (--cursorIndex) * 2;
        }
        endDigit = cursorIndex * 2 + cursor - 1;

        if (cursor > 0) {
          for (var index = startDigit; index < endDigit; ++index) {
            digits[index] = digits[index + 1];
          }
          digits[endDigit] = 0;

          cursor = --cursors[cursorIndex];
        }

        if (cursor == 0 && activeCursor > 0) {
          var allZero = true;
          for (var digit in digits) {
            if (digit != 0) {
              allZero = false;
              break;
            }
          }

          if (allZero) {
            activeCursor = 0;
          }
        }
      });
    };
  }

  String timerString(int index) {
    return digits[index + 1].toString() + digits[index].toString();
  }

  @override
  Widget build(BuildContext context) {
    TextTheme theme = Theme.of(context).textTheme;

    var nonZero = false;
    for (var digit in digits) {
      if (digit != 0) {
        nonZero = true;
        break;
      }
    }

    return Padding(
      padding:
          EdgeInsets.fromLTRB(0, 0, 0, (theme.headline2?.fontSize ?? 0) / 2),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Padding(
          padding: EdgeInsets.all((theme.headline2?.fontSize ?? 0) / 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              createTimerText(
                timerString(4),
                getTextColor(2, primaryColor, theme.headline2?.color),
                timeButton(2),
                theme,
              ),
              createTimerText(":", primaryColor, null, theme),
              createTimerText(
                timerString(2),
                getTextColor(1, primaryColor, theme.headline2?.color),
                timeButton(1),
                theme,
              ),
              createTimerText(":", primaryColor, null, theme),
              createTimerText(
                timerString(0),
                getTextColor(0, primaryColor, theme.headline2?.color),
                timeButton(0),
                theme,
              ),
            ],
          ),
        ),
        Column(
          children: [
            Row(
              children: [
                createDigitTextButton("1", pressDigit(1), theme),
                createDigitTextButton("2", pressDigit(2), theme),
                createDigitTextButton("3", pressDigit(3), theme),
              ],
            ),
            Row(
              children: [
                createDigitTextButton("4", pressDigit(4), theme),
                createDigitTextButton("5", pressDigit(5), theme),
                createDigitTextButton("6", pressDigit(6), theme),
              ],
            ),
            Row(
              children: [
                createDigitTextButton("7", pressDigit(7), theme),
                createDigitTextButton("8", pressDigit(8), theme),
                createDigitTextButton("9", pressDigit(9), theme),
              ],
            ),
            Row(
              children: [
                createDigitButton(
                    Icon(Icons.add, color: theme.headline4?.color),
                    null,
                    theme),
                createDigitTextButton("0", pressDigit(0), theme),
                createDigitButton(
                    Icon(Icons.backspace_outlined,
                        color: theme.headline4?.color),
                    backspace(),
                    theme),
              ],
            ),
          ],
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                0, (theme.headline3?.fontSize ?? 0) / 4, 0, 0),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(200)),
              color: nonZero ? primaryColor : Colors.grey,
              child: TextButton(
                onPressed: () {
                  int time = digits[5] * 10 + digits[4];
                  time = time * 60 + digits[3] * 10 + digits[2];
                  time = time * 60 + digits[1] * 10 + digits[0];

                  if (time != 0) {
                    startTimer(time);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.all((theme.headline3?.fontSize ?? 0) / 4),
                  child: const Icon(Icons.play_arrow, color: Colors.white),
                ),
              ),
            ),
          ),
        )
      ]),
    );
  }
}
