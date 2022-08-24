import 'package:flutter/material.dart';

typedef BackContext<T> = Map<String, bool Function()>;

class BackButtonProviderDelegate<T> {
  BackButtonProviderDelegate(this.listeners);

  final BackContext<T> listeners;
  void Function(bool)? defaultAction;

  void backPressed(T? state) {
    var action = defaultAction;
    if (state != null) {
      var listener = listeners[state];
      if (listener != null) {
        if (!listener() && action != null) {
          action(true);
        }
        return;
      }
    }

    if (action != null) {
      action(false);
    }
  }
}

class BackButtonProvider<T> extends StatelessWidget {
  const BackButtonProvider(this.backContext, this.state,
      {this.defaultAction, required this.child, Key? key})
      : super(key: key);

  final BackContext<T> backContext;
  final T? Function() state;
  final void Function(bool)? defaultAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: child,
      onWillPop: () async {
        var s = state();
        if (s != null) {
          var listener = backContext[s];
          if (listener != null) {
            if (!listener() && defaultAction != null) {
              defaultAction!(true);
            }
            return false;
          }
        }
        if (defaultAction != null) {
          defaultAction!(false);
        }

        return false;
      },
    );
  }
}

abstract class BackButtonWidget<T> extends StatefulWidget {
  const BackButtonWidget(this.backContext, this.backId, {Key? key})
      : super(key: key);

  final BackContext<T> backContext;
  final T backId;
}

abstract class BackButtonState<H extends BackButtonWidget> extends State<H> {
  bool onBackPressed();

  @override
  void initState() {
    super.initState();

    widget.backContext[widget.backId] = onBackPressed;
  }

  @override
  void dispose() {
    super.dispose();

    widget.backContext.remove(widget.backId);
  }
}
