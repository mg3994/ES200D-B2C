import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:crclib/catalog.dart';

class BleController {
  final crc8 = Crc8Maxim();
  final frb = FlutterReactiveBle();
  late StreamSubscription<ConnectionStateUpdate> c;
  late QualifiedCharacteristic tx;
  late QualifiedCharacteristic rx;
  final devId = 'DC:3D:BD:E7:8E:5C'; // use nrf connect from playstore to find
  var status = 'connect to bluetooth'.obs;
  var buttonStatus = '0'.obs;
  // List<int> packet = [0x41, 0x41, 0x41];
  // List<int> ledOn = [0x4f, 0x4f, 0x4f];
  // List<int> ledOff = [0x46, 0x46, 0x46];
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

  ///Commands

  void sendData(val) async {
    //reboot
//packet[0]=val.toInt();
    await sendOff();
    Future.delayed(Duration(milliseconds: 500));
    await sendOn();
    Future.delayed(Duration(milliseconds: 500));
    await sendOn();
    Future.delayed(Duration(milliseconds: 500));
    await sendOn();
  }

  void sendOn() async {
    int onCommandByte = genCommandByte(false, true, true, false, true);
    await sendCommand(
      onCommandByte,
    );
  }

  void sendOff() async {
    int offCommandByte = genCommandByte(false, true, false, true, false);
    await sendCommand(
      offCommandByte,
    );
  }

  ///Commands

  void connect() async {
    status.value = 'connecting...';
    c = frb.connectToDevice(id: devId).listen((state) {
      if (state.connectionState == DeviceConnectionState.connected) {
        status.value = 'connected!';

        tx = QualifiedCharacteristic(
            serviceId: Uuid.parse("0000ffe0-0000-1000-8000-00805f9b34fb"),
            characteristicId:
                Uuid.parse("8ec90003-f315-4f60-9fb8-838830daea50"),
            deviceId: devId);

        rx = QualifiedCharacteristic(
            serviceId: Uuid.parse("0000ffe0-0000-1000-8000-00805f9b34fb"),
            characteristicId:
                Uuid.parse("8ec90003-f315-4f60-9fb8-838830daea50"),
            deviceId: devId);

        frb.subscribeToCharacteristic(rx).listen((data) {
          String temp = utf8.decode(data);
          buttonStatus.value = temp;
        });
      }
    });
  }
}
