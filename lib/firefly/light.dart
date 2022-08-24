import 'dart:ui';

import 'package:flutter/material.dart';

class Light {
  String name, address;
  LightState? state;

  Light({required this.name, required this.address});
}

class LightState {
  final int count;
  int brightness, fade;
  FormulaInfo hue, sat, val;

  final List<void Function(int)> updateListeners = [];

  LightState(
      {required this.count,
      required this.brightness,
      required this.fade,
      required this.hue,
      required this.sat,
      required this.val});

  void update(int flags,
      {int? brightness,
      int? fade,
      FormulaInfo? hue,
      FormulaInfo? sat,
      FormulaInfo? val}) {
    if (brightness != null) this.brightness = brightness;
    if (fade != null) this.fade = fade;
    if (hue != null) this.hue = hue;
    if (sat != null) this.sat = sat;
    if (val != null) this.val = val;

    for (var listener in updateListeners) {
      listener(flags);
    }
  }

  HSVColor parseColor(HSVColor def) {
    var h = int.tryParse(hue.value),
        s = int.tryParse(sat.value),
        v = int.tryParse(val.value);

    return HSVColor.fromAHSV(
      1,
      h == null ? def.hue : h / 255.0 * 360,
      s == null ? def.saturation : s / 255.0,
      v == null ? def.value : v / 255.0,
    );
  }
}

class FormulaInfo {
  final int type;
  final String value;

  FormulaInfo(this.type, this.value);
}
