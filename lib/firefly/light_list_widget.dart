import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../widget.dart';
import 'light.dart';
import 'light_widget.dart';

class LightListWidget extends BackButtonWidget<String> {
  const LightListWidget(super.backContext, super.backId, {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LightListState();
}

class _LightListState extends BackButtonState<LightListWidget> {
  final _listKey = GlobalKey<AnimatedListState>();

  final List<Light> _lights = [];
  var _adding = false;
  var addName = "", addAddress = "";

  Light? _activeLight;

  final _backProvider = BackButtonProviderDelegate<String>({});

  @override
  void initState() {
    super.initState();

    _backProvider.defaultAction = (_) {
      setState(() {
        _activeLight = null;
      });
    };

    SharedPreferences.getInstance().then((preferences) {
      setState(() {
        _lights.addAll((preferences.getStringList("lights") ?? []).map((l) {
          var split = l.split("::");
          return Light(name: split[0], address: split[1]);
        }));
        var count = _lights.length;
        for (int i = 0; i < count; i++) {
          _listKey.currentState?.insertItem(i, duration: animationTime);
        }
      });
    });
  }

  @override
  bool onBackPressed() {
    var light = _activeLight;
    if (light == null) {
      return false;
    } else {
      _backProvider.backPressed("light:${light.name}");
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    var text = Theme.of(context).textTheme;
    var screenWidth = MediaQuery.of(context).size.width;

    var light = _activeLight;

    if (light != null) {
      return LightWidget(_backProvider, light);
    }

    return Column(
      children: [
        createPaddedIcon(Icons.light_mode, Colors.white, screenWidth / 6, () {
          setState(() {
            if (addName.isNotEmpty && addAddress.isNotEmpty) {
              var light = Light(name: addName, address: addAddress);
              _lights.add(light);
              _listKey.currentState
                  ?.insertItem(_lights.length - 1, duration: animationTime);

              SharedPreferences.getInstance().then((preferences) {
                var list = preferences.getStringList("lights") ?? [];
                list.add("${light.name}::${light.address}");
                preferences.setStringList("lights", list);
              });
            }
            addName = "";
            addAddress = "";
            _adding = !_adding;
          });
        }, background: primaryColor),
        AnimatedCrossFade(
          crossFadeState:
          _adding ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: animationTime,
          firstChild: AnimatedList(
            key: _listKey,
            initialItemCount: _lights.length,
            shrinkWrap: true,
            itemBuilder: (context, index, animation) {
              return SizeTransition(
                key: UniqueKey(),
                sizeFactor: animation,
                child: Center(
                  child: Padding(
                    padding:
                    EdgeInsets.all((text.headline4?.fontSize ?? 0) / 12),
                    child: Card(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _activeLight = _lights[index];
                          });
                        },
                        onLongPress: () {
                          setState(() {
                            var light = _lights[index];
                            _lights.removeAt(index);
                            SharedPreferences.getInstance().then((preferences) {
                              var list =
                                  preferences.getStringList("lights") ?? [];
                              list.removeAt(index);
                              preferences.setStringList("lights", list);
                            });
                            _listKey.currentState?.removeItem(index,
                                    (context, animation) {
                                  return TextButton(
                                    onPressed: () {},
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                          (text.headline4?.fontSize ?? 0) / 4),
                                      child: Text(
                                        light.name,
                                        style: text.headline4?.merge(
                                            const TextStyle(color: Colors.black)),
                                      ),
                                    ),
                                  );
                                });
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.all(
                              (text.headline4?.fontSize ?? 0) / 4),
                          child: Text(
                            _lights[index].name,
                            style: text.headline4
                                ?.merge(const TextStyle(color: Colors.black)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          secondChild: FractionallySizedBox(
            widthFactor: 0.75,
            child: Column(
              children: [
                Card(child: FormField<String>(builder: (field) {
                  return TextField(
                    controller: TextEditingController(text: ""),
                    onChanged: (value) => addName = value,
                    textAlign: TextAlign.center,
                    style: text.headline5,
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: "Name"),
                  );
                })),
                Card(child: FormField<String>(builder: (field) {
                  return TextField(
                    controller: TextEditingController(text: ""),
                    onChanged: (value) => addAddress = value,
                    textAlign: TextAlign.center,
                    style: text.headline5,
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: "Address"),
                  );
                })),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
