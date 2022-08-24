/*
How does it behave?
> Create a connection by specifying ip (optional port, default = 55420)
> Every <connectInterval> seconds, send out an info packet (repeats this <maxConnectAttemps> times, then considers it a failed connection)
> When a response is received containing light info, the connection is "established"
> If the user pauses the app and comes back, if 1 minute has passed, close the connection
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bamboo/firefly/light.dart';

List<int> _constructPacket(int packetId, List<int> data) {
  var length = data.length + 1;
  return [(length >> 8) & 0xFF, length & 0xFF, packetId, ...data];
}

class FakeLightConnection {
  final Light light;
  final LightConnectionListener listener;

  FakeLightConnection(this.light, this.listener) {
    Timer(const Duration(seconds: 1), () {
      light.state = LightState(
        count: 300,
        brightness: 1,
        fade: 1,
        hue: FormulaInfo(0, "128"),
        sat: FormulaInfo(0, "255"),
        val: FormulaInfo(0, "255"),
      );

      listener(true);
    });
  }

  void update(
      {int? brightness,
      int? fade,
      FormulaInfo? hue,
      FormulaInfo? sat,
      FormulaInfo? val}) {}

  void close() {}
}

class LightConnection {
  static const port = 55420;
  static const connectInterval = 5;
  static const maxConnectAttempts = 4;

  final Light light;
  final LightConnectionListener listener;

  final InternetAddress _address;
  late RawDatagramSocket _socket;
  late Timer _connectionTimer;

  LightConnection(this.light, this.listener)
      : _address = (InternetAddress(light.address)) {
    RawDatagramSocket.bind(InternetAddress.anyIPv4, port)
        .then((RawDatagramSocket socket) {
      _socket = socket;

      socket.listen((e) {
        Datagram? dg = socket.receive();
        if (dg != null) {
          var data = dg.data;

          for (int index = 0; index < data.length;) {
            // var length = data[index++] << 8 | data[index++];
            index += 2; // Length
            var packetId = data[index++];

            switch (packetId) {
              case 0: // Pong
                break;
              case 1: // Update response
                break;
              case 2: // Status response
                _connectionTimer.cancel();

                light.state = LightState(
                  count: data[index++] << 8 | data[index++],
                  brightness: data[index++],
                  fade: data[index++] << 8 | data[index++],
                  hue: FormulaInfo(
                      data[index++],
                      const Utf8Decoder()
                          .convert(data, index + 1, index += data[index] + 1)),
                  sat: FormulaInfo(
                      data[index++],
                      const Utf8Decoder()
                          .convert(data, index + 1, index += data[index] + 1)),
                  val: FormulaInfo(
                      data[index++],
                      const Utf8Decoder()
                          .convert(data, index + 1, index += data[index] + 1)),
                );

                print("State is now ${light.state}!");

                listener(true);
                break;
            }
          }
        }
      });

      var statusPacket = _constructPacket(2, []);

      _connectionTimer =
          Timer.periodic(const Duration(seconds: connectInterval), (timer) {
        if (timer.tick >= maxConnectAttempts) {
          timer.cancel();
          socket.close();
          listener(false);
        } else {
          socket.send(statusPacket, _address, port);
        }
      });
      socket.send(statusPacket, _address, port);
    });
  }

  void update(
      {int? brightness,
      int? fade,
      FormulaInfo? hue,
      FormulaInfo? sat,
      FormulaInfo? val}) {
    int flags = 0;
    List<int> packet = [0];
    var state = light.state;

    if (brightness != null) {
      flags |= 1;
      packet.add(brightness);
      state?.brightness = brightness;
    }
    if (fade != null) {
      flags |= 2;
      packet.add((fade >> 8) & 0xFF);
      packet.add(fade & 0xFF);
      state?.fade = fade;
    }
    void append(
        int flag, FormulaInfo? info, void Function(FormulaInfo) update) {
      if (info != null) {
        flags |= flag;
        packet.add(info.type);
        packet += const Utf8Encoder().convert(info.value);
        packet.add(0);
        update(info);
      }
    }

    append(4, hue, (h) => state?.hue = h);
    append(8, sat, (s) => state?.sat = s);
    append(16, val, (v) => state?.val = v);

    packet[0] = flags;

    _socket.send(_constructPacket(1, packet), _address, port);

    state!.update(
      flags,
      brightness: brightness,
      fade: fade,
      hue: hue,
      sat: sat,
      val: val,
    );
  }

  void close() {
    _connectionTimer.cancel();
    _socket.close();
  }
}

typedef LightConnectionListener = void Function(bool);
