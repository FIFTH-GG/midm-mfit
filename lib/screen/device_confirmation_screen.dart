import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mfit/viewmodel/bluetooth_viewmodel.dart';
import 'package:provider/provider.dart';

import '../core/bluetooth/bluetooth_protocol.dart';

class DeviceConfirmationScreen extends StatefulWidget {
  final BluetoothDevice device;
  const DeviceConfirmationScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceConfirmationScreen> createState() => _DeviceConfirmationScreenState();
}

class _DeviceConfirmationScreenState extends State<DeviceConfirmationScreen> {
  final bluetoothProtocol = BluetoothProtocol();
  StreamSubscription<List<int>>? _rxSubscription;

  late String deviceID;
  late String cartridgeIdStr;
  late String cartridgeCount;
  late String totalCount;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.microtask(() async {
      final bluetooth = context.read<BluetoothViewModel>();
      await bluetooth.connectToDevice(widget.device);
      _sendStateRequest(bluetooth);
    });

    bluetoothProtocol.onPacketReceived = (String command, String data) {
      if (!mounted) return;
      _handleResponse(command, data);
    };
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _rxSubscription?.cancel();
    super.dispose();
  }

  Future<void> _sendStateRequest(BluetoothViewModel bluetooth) async {
    final tx = bluetooth.txCharacteristic;
    final rx = bluetooth.rxCharacteristic;

    if(tx != null && rx != null) {
      await _rxSubscription?.cancel();

      String message = bluetoothProtocol.createStateMessage();
      await tx.write(utf8.encode(message), withoutResponse: tx.properties.writeWithoutResponse);
      if(!rx.isNotifying) {
        await rx.setNotifyValue(true);
      }

      await _rxSubscription?.cancel();

      _rxSubscription = rx.lastValueStream.listen((data) {
        bluetoothProtocol.onDataReceived(data);
      });
    }
  }

  void _sendIdentifyRequest(BluetoothViewModel bluetooth) async {
    final tx = bluetooth.txCharacteristic;
    final rx = bluetooth.rxCharacteristic;

    if(tx != null && rx != null) {
      String message = bluetoothProtocol.createIdentifyMessage();
      await tx.write(utf8.encode(message), withoutResponse: tx.properties.writeWithoutResponse);
    }
  }

  void _handleResponse(String command, String data) async {
    print("Received Command: $command, Data: $data");

    if(!mounted) return;
    final bluetooth = context.read<BluetoothViewModel>();
    if(command == "STA") {
      deviceID = data.substring(0, 11);
      cartridgeIdStr = data.substring(11, 25);
      cartridgeCount = data.substring(25, 31);
      totalCount = data.substring(31, 37);
      print(deviceID);
      print(cartridgeIdStr);
      print(cartridgeCount);
      print(totalCount);

      _sendIdentifyRequest(bluetooth);
    } else if (command == "IDF") {
      if (data == "1") {
        if(mounted) Navigator.pop(context, {'result': true, 'ID':deviceID, 'C_ID':cartridgeIdStr, 'C_CNT':cartridgeCount, 'T_CNT':totalCount});
      } else if (data == "0") {
        await bluetooth.disconnectFromDevice();
        //bluetoothManager.disconnectToDevice();
        if(mounted) Navigator.pop(context, {'result': false});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Spacer(), // 상단 여백
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/device.png', width: 200, height: 200),
                const SizedBox(height: 25),
                const Text(
                  'If this is the correct device to connect,\nPlease press the YES button on the device screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          const Spacer(), // 텍스트와 버튼 사이 여백
          Padding(
            padding: const EdgeInsets.only(bottom: 40), // 버튼 아래 여백 조정 가능
            child: _buildCancelButton(context),
          ),
        ],
      ),
    );
  }
}
Widget _buildCancelButton(BuildContext context) {
  return Container(
    width: 300,
    child: TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      ),
      child: const Text('Cancel', style: TextStyle(fontSize: 16)),
    ),
  );
}