# ES200D-B2C
TODO: it is my Rough Sketch , not usefull

```dart
import 'dart:typed_data';

import 'package:crclib/catalog.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

void main(List<String> args) {
  //variables
  int speed = 25;
  bool lightOn = true;
  bool lightBlink = true;
  bool fastAcceleration = true;
// TODO: all other commands
}

class Commands {
  void keepActive(
      {required int speed,
      bool fastAcceleration = false,
      bool kph = true,
      bool lightOn = true,
      bool lightBlink = false}) {
    Sender().sendCommand(
        UseCases().startCommand(fastAcceleration, kph, lightOn, lightBlink),
        speed);
  }

  void unlock(
      {required int speed,
      bool fastAcceleration = false,
      bool kph = true,
      bool lightOn = true,
      bool lightBlink = false}) async {
    Sender().sendCommand(UseCases().stopCommand(lightBlink));
    Future.delayed(Duration(milliseconds: 500));

    Sender().sendCommand(
        UseCases().startCommand(false, kph, lightOn, false), speed);
    Future.delayed(Duration(milliseconds: 500));
  }

  void lock({bool lightBlink = false}) {
    Sender().sendCommand(UseCases().stopCommand(lightBlink));
    Future.delayed(Duration(milliseconds: 500));
  }

// Sequence used to reboot scooter to bypass shutdown after 2 minutes

  void reboot(
      {required int speed,
      bool fastAcceleration = false,
      bool kph = true,
      bool lightOn = true,
      bool lightBlink = false}) {
    Sender().sendCommand(UseCases().stopCommand(lightBlink));

    Future.delayed(Duration(milliseconds: 500));

    Sender().sendCommand(
        UseCases().startCommand(fastAcceleration, kph, lightOn, lightBlink),
        speed);
    Future.delayed(Duration(milliseconds: 500));
    Sender().sendCommand(
        UseCases().startCommand(fastAcceleration, kph, lightOn, lightBlink),
        speed);
    Future.delayed(Duration(milliseconds: 500));
    Sender().sendCommand(
        UseCases().startCommand(fastAcceleration, kph, lightOn, lightBlink),
        speed);
    Future.delayed(Duration(milliseconds: 500));
  }
}

class UseCases {
  startCommand(bool fastAcceleration, bool kph, bool lightOn, bool lightBlink) {
    return Helper()
        .genCommandByte(fastAcceleration, kph, lightOn, lightBlink, true);
  }

  stopCommand(bool lightBlink) {
    return Helper().genCommandByte(false, true, false, lightBlink, false);
  }
}

class Helper {
  int genCommandByte(bool fastAcceleration, bool kph, bool lightOn,
      bool lightBlink, bool powerOn) {
    List<bool> bits = [
      powerOn,
      lightBlink,
      lightOn,
      false, // 0 in C++ code
      kph,
      fastAcceleration,
      false, // 0 in C++ code
      false, // 0 in C++ code
    ];

    int c = 0;
    for (int i = 0; i < 8; i++) {
      if (bits[i]) {
        c |= 1 << i;
      }
    }
    return c;
  }
}

class Sender {
  static const devId =
      'DC:3D:BD:E7:8E:5C'; // use nrf connect from playstore to find
  //then contect
  // TODO: connection code
  //TODO: Find these

  QualifiedCharacteristic tx = QualifiedCharacteristic(
      serviceId:
          Uuid.parse("0000ffe0-0000-1000-8000-00805f9b34fb"), // Find out these
      characteristicId: Uuid.parse(
          "0000ffe1-0000-1000-8000-00805f9b34fb"), // // Find out these
      deviceId: devId);
  QualifiedCharacteristic rx = QualifiedCharacteristic(
      serviceId: Uuid.parse(
          "0000ffe0-0000-1000-8000-00805f9b34fb"), //// Find out these
      characteristicId:
          Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb"), // Find out these
      deviceId: devId);
  final frb = FlutterReactiveBle();
  final crc8 = Crc8Maxim();
  Future<void> sendCommand(int commandByte, [int speed = 20]) async {
    // commandByte is responsible for making it turnon or off
    List<int> buf = List.filled(6, 0); // Equivalent to `uint8_t buf[6];`
    buf[0] = 0xA6;
    buf[1] = 0x12;
    buf[2] = 0x02;
    buf[3] = commandByte;
    buf[4] = speed;
    buf[5] = crc8
        .convert([buf[0], buf[1], buf[2], buf[3], buf[4]])
        .toBigInt()
        .toInt();

    // Transmit via Bluetooth characteristic
    await frb.writeCharacteristicWithoutResponse(tx, value: buf);
    // await characteristic.write(Uint8List.fromList(buf), withoutResponse: true);
    // print("Command sent to ESC: ${Uint8List.fromList(buf)}");
  }
}
```
