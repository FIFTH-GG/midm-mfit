import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../viewmodel/bluetooth_viewmodel.dart';


class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<BluetoothViewModel>().connectToDevice(widget.device);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }


  void _navigateToCartridgeScreen(BluetoothDevice device) async {
    /*
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartridgeScreen()),
    );*/
  }


  Widget _buildButton(String string, Function()? onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: true ? onPressed: null, // 연결 안되면 비활성화
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            string,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bluetooth = context.watch<BluetoothViewModel>();
    final isConnected = bluetooth.connectionState == BluetoothConnectionState.connected;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('Device'),
        actions: [
          TextButton(
            onPressed: () {
            },
            child: Text('Remove', style: TextStyle(color: Colors.red),),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      blurRadius: 1.0,
                      spreadRadius: 0.0,
                      offset: const Offset(0,0),
                    ),
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      blurRadius: 1.0,
                      spreadRadius: 0.0,
                      offset: const Offset(2,2),
                    ),
                  ]
              ),
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 10,),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/device.png',
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.device.name,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.device.id.toString(),
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Registration Date : 2025-03-04',
                              style: TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Connected',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10,),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16), // 좌우 여백 10
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      blurRadius: 1.0,
                      spreadRadius: 0.0,
                      offset: const Offset(0,0),
                    ),
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      blurRadius: 1.0,
                      spreadRadius: 0.0,
                      offset: const Offset(2,2),
                    ),
                  ]
              ),
              width: double.infinity, // 화면 끝까지 확장
              height: 200,
              child: const Text('data'),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [_buildButton("카트리지", () => _navigateToCartridgeScreen(widget.device)), _buildButton("화장품", () {})],
                  ),
                  Row(
                    children: [_buildButton("A/S 지원", () {}), _buildButton("", () {})],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}