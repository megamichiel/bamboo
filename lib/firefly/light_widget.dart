import 'dart:ui';

import 'package:bamboo/firefly/light_connection.dart';
import 'package:bamboo/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'light.dart';
import '../main.dart';

class LightWidget extends StatefulWidget {
  final BackButtonProviderDelegate<String> backProvider;
  final Light light;

  const LightWidget(this.backProvider, this.light, {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LightState();
}

class _LightState extends State<LightWidget> {
  late LightConnection _connection;
  var _loading = true;

  @override
  void initState() {
    super.initState();

    _connection = LightConnection(widget.light, (success) {
      if (success) {
        setState(() {
          _loading = false;
        });
      } else {
        widget.backProvider.backPressed(null);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    _connection.close();
  }

  @override
  Widget build(BuildContext context) {
    TextTheme text = Theme.of(context).textTheme;
    var fontSize = text.headline4?.fontSize ?? 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(fontSize, 0, fontSize, 0),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Card(
          color: primaryColor,
          child: TextButton(
            onPressed: () {
              widget.backProvider.backPressed("light:${widget.light.name}");
            },
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.arrow_back,
                        color: Colors.grey.shade200,
                        size: text.headline4?.fontSize ?? 0),
                  ),
                ),
                Text(
                  widget.light.name,
                  style: text.headline4
                      ?.merge(TextStyle(color: Colors.grey.shade200)),
                ),
                Expanded(
                  child: Visibility(
                    visible: _loading,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(fontSize / 2, 0, 0, 0),
                        child: const CircularProgressIndicator(
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_loading)
          Column(
            children: [
              ColorWidget(widget.backProvider.context,
                  "light:${widget.light.name}", widget.light, _connection),
              Card(
                child: BrightnessWidget(widget.light, _connection),
              )
            ],
          ),
      ]),
    );
  }
}

class ColorWidget extends BackButtonWidget<String> {
  const ColorWidget(
      super.backContext, super.backId, this.light, this.connection,
      {Key? key})
      : super(key: key);

  final Light light;
  final LightConnection connection;

  @override
  State<StatefulWidget> createState() => _ColorState();
}

class _ColorState extends BackButtonState<ColorWidget> {
  // 0 = overview, 1 = presets, 2 = palette
  var state = 0, formerState = 0;

  var _loadedPresets = <Preset>[];
  var newPreset = NewPreset("");

  @override
  bool onBackPressed() {
    if (state == 0) {
      return false;
    } else {
      setState(() {
        state = 0;
      });
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget iconButton(
        IconData icon, void Function() press, void Function()? longPress) {
      return Expanded(
        child: FractionallySizedBox(
          widthFactor: 0.6,
          child: AspectRatio(
            aspectRatio: 1,
            child: Card(
              child: TextButton(
                onPressed: press,
                onLongPress: longPress,
                child: FractionallySizedBox(
                  widthFactor: 0.6,
                  heightFactor: 0.6,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: Icon(icon, color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    var midWidget;
    switch (formerState) {
      case 1:
        midWidget =
            PresetsWidget(widget.light, widget.connection, _loadedPresets);
        break;
      case 2:
        midWidget = PickerWidget(widget.light, widget.connection);
        break;
      default:
        midWidget =
            NewPresetWidget(widget.light, widget.connection, newPreset, () {
          var preset = newPreset;

          String s(Object? value) => value == null ? "" : value.toString();

          SharedPreferences.getInstance().then((preferences) {
            var list = preferences.getStringList("lightPresets") ?? [];
            list.add([
              preset.name,
              preset.onlyIf(1, preset.brightness),
              preset.onlyIf(2, preset.fade),
              preset.onlyIf(4, preset.hue),
              preset.onlyIf(8, preset.sat),
              preset.onlyIf(16, preset.val)
            ].map(s).join("::"));
            preferences.setStringList("lightPresets", list);
          });

          setState(() {
            state = 0;
          });
        });
    }

    return AnimatedCrossFade(
      firstChild: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          iconButton(Icons.bookmark_border, () {
            SharedPreferences.getInstance().then((preferences) {
              _loadedPresets =
                  (preferences.getStringList("lightPresets") ?? []).map((s) {
                var split = s.split("::");
                T? map<T>(String s, T map(String)) {
                  return s.isEmpty ? null : map(s);
                }

                return Preset(
                  split[0],
                  brightness: map(split[1], (s) => int.parse(s)),
                  fade: map(split[2], (s) => int.parse(s)),
                  hue: map(split[3], (s) => s),
                  sat: map(split[4], (s) => s),
                  val: map(split[5], (s) => s),
                );
              }).toList();
            });
            setState(() {
              state = formerState = 1;
            });
          }, () {
            setState(() {
              var state = widget.light.state!;
              var preset = newPreset;

              preset.name = "";
              preset.brightness = state.brightness;
              preset.fade = state.fade;
              preset.hue = Preset.formulaToString(state.hue);
              preset.sat = Preset.formulaToString(state.sat);
              preset.val = Preset.formulaToString(state.val);
              preset.enabled = 0;

              this.state = formerState = 3;
            });
          }),
          iconButton(Icons.color_lens, () {
            setState(() {
              state = formerState = 2;
            });
          }, null),
        ],
      ),
      secondChild: midWidget,
      crossFadeState:
          state == 0 ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: animationTime,
    );
  }
}

class PresetsWidget extends StatefulWidget {
  const PresetsWidget(this.light, this.connection, this.presets, {Key? key})
      : super(key: key);

  final Light light;
  final LightConnection connection;
  final List<Preset> presets;

  @override
  State<StatefulWidget> createState() => PresetsState();
}

class PresetsState extends State<PresetsWidget> {
  final _listKey = GlobalKey<AnimatedListState>();
  late final _presets = widget.presets;

  @override
  void initState() {
    super.initState();

    widget.light.state!.updateListeners.add(lightUpdated);
  }

  @override
  void dispose() {
    super.dispose();

    widget.light.state!.updateListeners.remove(lightUpdated);
  }

  void lightUpdated(int flags) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    TextTheme text = Theme.of(context).textTheme;
    var fontSize = text.headline4?.fontSize ?? 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(fontSize / 2, 0, fontSize / 2, 0),
      child: Column(
        children: [
          AnimatedList(
            key: _listKey,
            initialItemCount: (_presets.length + 1) ~/ 2,
            shrinkWrap: true,
            itemBuilder: (context, index, animation) {
              Widget presetButton(int i) {
                bool active = _presets[i].isActive(widget.light.state!);

                return Expanded(
                  child: AspectRatio(
                    aspectRatio: 2,
                    child: Card(
                      color: active ? accentColor.shade100 : null,
                      child: TextButton(
                        onPressed: () {
                          var preset = _presets[i];

                          widget.connection.update(
                            brightness: preset.brightness,
                            fade: preset.fade,
                            hue: Preset.asFormula(preset.hue),
                            sat: Preset.asFormula(preset.sat),
                            val: Preset.asFormula(preset.val),
                          );
                        },
                        onLongPress: () {
                          setState(() {
                            var preset = _presets[i];
                            _presets.removeAt(i);
                            if (_presets.length % 2 == 0) {
                              _listKey.currentState?.removeItem(i ~/ 2,
                                  (context, animation) {
                                return TextButton(
                                    onPressed: () {},
                                    child: Center(
                                      child: Text(
                                        preset.name,
                                        style: text.headline5?.merge(
                                            const TextStyle(
                                                color: Colors.black)),
                                      ),
                                    ));
                              });
                            }
                            SharedPreferences.getInstance().then((preferences) {
                              var list =
                                  preferences.getStringList("lightPresets")!;
                              list.removeAt(i);
                              preferences.setStringList("lightPresets", list);
                            });
                          });
                        },
                        child: Center(
                          child: Text(
                            _presets[i].name,
                            style: text.headline5
                                ?.merge(const TextStyle(color: Colors.black)),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SizeTransition(
                key: UniqueKey(),
                sizeFactor: animation,
                child: Padding(
                  padding:
                      EdgeInsets.fromLTRB(0, fontSize / 16, 0, fontSize / 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      presetButton(index * 2),
                      index * 2 + 1 < _presets.length
                          ? presetButton(index * 2 + 1)
                          : Expanded(child: Container())
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PickerWidget extends StatefulWidget {
  const PickerWidget(this.light, this.connection, {Key? key}) : super(key: key);

  final Light light;
  final LightConnection connection;

  @override
  State<StatefulWidget> createState() => PickerState();
}

class PickerState extends State<PickerWidget> {
  late Color _color =
      widget.light.state!.parseColor(HSVColor.fromColor(Colors.red)).toColor();

  @override
  void initState() {
    super.initState();

    widget.light.state!.updateListeners.add(lightUpdated);
  }

  @override
  void dispose() {
    super.dispose();

    widget.light.state!.updateListeners.remove(lightUpdated);
  }

  void lightUpdated(int flags) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    TextTheme text = Theme.of(context).textTheme;
    var fontSize = text.headline4?.fontSize ?? 0;

    return Card(
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(fontSize / 2, fontSize / 2, fontSize / 2, 0),
        child: ColorPicker(
          pickerColor: _color,
          paletteType: PaletteType.hsv,
          displayThumbColor: true,
          enableAlpha: false,
          hexInputBar: false,
          labelTypes: const [],
          pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(5)),
          onColorChanged: (color) {
            var oldColor = _color;
            _color = color;

            var old = HSVColor.fromColor(oldColor);
            var hsv = HSVColor.fromColor(color);

            FormulaInfo? maybeUpdate(double prev, double now) {
              return now != prev
                  ? FormulaInfo(0, (now * 255).round().toString())
                  : null;
            }

            widget.connection.update(
              hue: maybeUpdate(old.hue / 360, hsv.hue / 360),
              sat: maybeUpdate(old.saturation, hsv.saturation),
              val: maybeUpdate(old.value, hsv.value),
            );
          },
        ),
      ),
    );
  }
}

class NewPresetWidget extends StatefulWidget {
  const NewPresetWidget(this.light, this.connection, this.preset, this.onSaved,
      {Key? key})
      : super(key: key);

  final Light light;
  final LightConnection connection;
  final NewPreset preset;
  final void Function() onSaved;

  @override
  State<StatefulWidget> createState() => NewPresetState();
}

class NewPresetState extends State<NewPresetWidget> {
  late final NewPreset preset = widget.preset;

  @override
  Widget build(BuildContext context) {
    TextTheme text = Theme.of(context).textTheme;
    var fontSize = text.headline4?.fontSize ?? 0;

    Widget textField(String hint, TextInputType? type, int flag, String? value,
        void Function(String) onChanged) {
      return Card(
        color: (preset.enabled & flag) == flag ? null : Colors.grey.shade500,
        child: FormField<String>(builder: (field) {
          return TextField(
            controller: TextEditingController(text: value ?? ""),
            focusNode: FocusNode()
              ..addListener(() {
                if ((preset.enabled & flag) != flag) {
                  setState(() => preset.enabled |= flag);
                }
              }),
            onChanged: onChanged,
            textAlign: TextAlign.center,
            style: text.headline5,
            keyboardType: type,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
            ),
          );
        }),
      );
    }

    const intType = TextInputType.numberWithOptions(decimal: false);

    String s(Object? o) => o == null ? "" : o.toString();

    return Padding(
      padding: EdgeInsets.fromLTRB(fontSize / 2, 0, fontSize / 2, 0),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: textField("Name", null, 0, widget.preset.name,
                      (value) => widget.preset.name = value),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: Card(
                    child: TextButton(
                      onPressed: widget.onSaved,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Icon(Icons.save, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: textField("Brightness", intType, 1, s(preset.brightness),
                    (v) {
                  preset.brightness =
                      v.isEmpty ? null : int.parse(v).clamp(0, 255);
                }),
              ),
              Expanded(
                child: textField("Fade", intType, 2, s(preset.fade), (v) {
                  preset.fade = v.isEmpty ? null : int.parse(v).clamp(0, 255);
                }),
              ),
            ],
          ),
          textField("Hue", null, 4, s(preset.hue),
              (value) => preset.hue = value.isEmpty ? null : value),
          Row(
            children: [
              Expanded(
                child: textField("Saturation", null, 8, s(preset.sat),
                    (value) => preset.sat = value.isEmpty ? null : value),
              ),
              Expanded(
                child: textField("Value", null, 16, s(preset.val),
                    (value) => preset.val = value.isEmpty ? null : value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BrightnessWidget extends StatefulWidget {
  const BrightnessWidget(this.light, this.connection, {Key? key})
      : super(key: key);

  final Light light;
  final LightConnection connection;

  @override
  State<StatefulWidget> createState() => BrightnessState();
}

class BrightnessState extends State<BrightnessWidget> {
  @override
  void initState() {
    super.initState();

    widget.light.state!.updateListeners.add(lightUpdated);
  }

  @override
  void dispose() {
    super.dispose();

    widget.light.state!.updateListeners.remove(lightUpdated);
  }

  void lightUpdated(int flags) {
    if ((flags & 1) != 0) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      min: 0.0,
      max: 255.0,
      divisions: 256,
      value: widget.light.state!.brightness.toDouble(),
      onChanged: (value) {
        widget.connection.update(brightness: value.round());
      },
    );
  }
}

class Preset {
  String name;
  int? brightness, fade;
  String? hue, sat, val;

  Preset(this.name, {this.brightness, this.fade, this.hue, this.sat, this.val});

  bool _compare(String? s, FormulaInfo form) {
    if (s == null) {
      return true;
    } else if (form.type == 0) {
      return s == form.value;
    } else {
      return s.isNotEmpty && s[0] == '.' && s.substring(1) == form.value;
    }
  }

  bool isActive(LightState state) {
    return (brightness == null || brightness == state.brightness) &&
        (fade == null || fade == state.fade) &&
        _compare(hue, state.hue) &&
        _compare(sat, state.sat) &&
        _compare(val, state.val);
  }

  static FormulaInfo? asFormula(String? s) {
    if (s == null) {
      return null;
    } else if (s.isNotEmpty && s[0] == '.') {
      return FormulaInfo(1, s.substring(1));
    } else {
      return FormulaInfo(0, s);
    }
  }

  static String formulaToString(FormulaInfo form) {
    return form.type == 0 ? form.value : ".${form.value}";
  }
}

class NewPreset extends Preset {
  NewPreset(super.name,
      {super.brightness, super.fade, super.hue, super.sat, super.val});

  int enabled = 0;

  T? onlyIf<T>(int flag, T value) {
    return (enabled & flag) == flag ? value : null;
  }
}
