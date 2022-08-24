import 'package:flutter/services.dart';

class AndroidCaller {
  static const platform = MethodChannel('bamboo/android');

  static Future<String> startTimer(int length) async {
    String result = "Failed";
    try {
      result = await platform.invokeMethod("setTimer", {
        "length": length,
      });
      // print('RESULT -> $result');
    } on PlatformException catch (e) {
      // print(e);
    }
    return result;
  }

  static void setNight(int value) {
    platform.invokeMethod("setNight", {
      "value": value
    });
  }

  static Future<int> getNight() async {
    int result;
    try {
      result = await platform.invokeMethod("getNight");
    } on PlatformException catch (e) {
      result = 0;
    }
    return result;
  }

  static void toast(String message) async {
    platform.invokeMethod("toast", {
      "message": message
    });
  }

  static void exit() {
    platform.invokeMethod("exit");
  }
}
