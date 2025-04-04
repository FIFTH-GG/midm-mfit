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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.microtask(() async {
      final bluetooth = context.read<BluetoothViewModel>();
      await bluetooth.connectToDevice(widget.device);
      _sendIdentifyRequest(bluetooth);
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

  void _sendIdentifyRequest(BluetoothViewModel bluetooth) async {
    final tx = bluetooth.txCharacteristic;
    final rx = bluetooth.rxCharacteristic;

    if(tx != null && rx != null) {
      await _rxSubscription?.cancel();

      String message = bluetoothProtocol.createIdentifyMessage();
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

  void _handleResponse(String command, String data) async {
    print("🎯 Received Command: $command, Data: $data");

    if(!mounted) return;
    final bluetooth = context.read<BluetoothViewModel>();

    if (command == "IDF") {
      if (data == "1") {
        if(mounted) Navigator.pop(context, true);
      } else if (data == "0") {
        await bluetooth.disconnectFromDevice();
        //bluetoothManager.disconnectToDevice();
        if(mounted) Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/device.png', width: 200, height: 200),
            const SizedBox(height: 20),
            const Text(
              '연결할 장비가 맞으시면\n장비 화면에서 OK 버튼을 눌러주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            _buildCancelButton(context),
          ],
        ),
      ),
    );
  }
}
/*
class CounterAssignmentInProgressScreen extends StatefulWidget {
  const CounterAssignmentInProgressScreen({super.key,});

  @override
  State<CounterAssignmentInProgressScreen> createState() => _CounterAssignmentInProgressScreenState();
}

class _CounterAssignmentInProgressScreenState extends State<CounterAssignmentInProgressScreen> {
  bool isProcessing = true; // 로딩 상태

  final BluetoothManager bluetoothManager = BluetoothManager();
  final BluetoothProtocol bluetoothProtocol = BluetoothProtocol();

  @override
  void initState() {
    super.initState();
    _sendCount();

    bluetoothProtocol.onPacketReceived = (String command, String data) {
      _handleResponse(command, data);
    };
  }

  void _sendCount() async {
    if(bluetoothManager.txCharacteristic != null) {
      String message = bluetoothProtocol.createCountMessage(0, 30000);
      await bluetoothManager.txCharacteristic!.write(utf8.encode(message), withoutResponse: bluetoothManager.txCharacteristic!.properties.writeWithoutResponse);
    }

    if (bluetoothManager.rxCharacteristic != null) {
      await bluetoothManager.rxCharacteristic!.setNotifyValue(true);
      bluetoothManager.rxCharacteristic!.lastValueStream.listen((data) {
        bluetoothProtocol.onDataReceived(data);
      });
    }
  }

  void _handleResponse(String command, String data) {
    print("🎯 Received Command: $command, Data: $data");

    if (command == "CNT") {
      if (data == "1") {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CounterAssignmentCompleteScreen()),
          );
        });
      } else if (data == "0") {
        bluetoothManager.disconnectToDevice();
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isProcessing ? Colors.yellow : Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bluetooth, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              "장비에 카운터를 부여 중입니다.\n잠시만 기다려주세요.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text('취소', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ 3. 카운터 부여 완료 화면
class CounterAssignmentCompleteScreen extends StatelessWidget {
  const CounterAssignmentCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ 초록색 체크 아이콘
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // ✅ 안내 문구
            const Text(
              '카운터 부여가 완료되었습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // ✅ 완료 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text('완료', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}*/

Widget _buildCancelButton(BuildContext context) {
  return TextButton(
    onPressed: () => Navigator.pop(context),
    style: TextButton.styleFrom(
      foregroundColor: Colors.red,
      side: const BorderSide(color: Colors.red),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
    ),
    child: const Text('취소', style: TextStyle(fontSize: 16)),
  );
}