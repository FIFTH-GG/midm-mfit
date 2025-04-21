import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodel/bluetooth_viewmodel.dart';
import 'cartridge_screen.dart';


class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  final String name;
  final String date;
  final Map<String, dynamic> map;

  const DeviceScreen({Key? key, required this.device, required this.name, required this.date, required this.map}) : super(key: key);

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
    widget.device.disconnect();
    super.dispose();
  }


  void _navigateToCartridgeScreen(BluetoothDevice device) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartridgeScreen(device: device,)),
    );
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

  Future<void> _removeDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();  // 연결 해제
    } catch (e) {
      debugPrint("BLE disconnect error: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList('connected_devices') ?? [];

    savedList.removeWhere((entry) => entry.startsWith(device.id.toString()));
    await prefs.setStringList('connected_devices', savedList);
    debugPrint("[삭제됨] connected_devices: $savedList");

    if (mounted) {
      Navigator.pop(context, {'removed': true});
    }
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
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Device'),
                  content: const Text('Are you sure you want to remove this device?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // 먼저 다이얼로그 닫고
                        _removeDevice(widget.device);
                      },
                      child: const Text('Remove', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
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
                              widget.name,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.device.id.toString(),
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Registration Date : ${widget.date}',
                              style: const TextStyle(fontSize: 12, color: Colors.black),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5.0,),
                  Text('Device ID : ${widget.map['ID']}', style: TextStyle(fontSize: 18, color: Colors.black),),
                  const SizedBox(height: 10.0,),
                  Text('Cartridge ID : ${widget.map['C_ID'] == 'AAAAAAAAAAAAAA' ? 'unknown' : widget.map['C_ID']}', style: TextStyle(fontSize: 18, color: Colors.black),),
                  const SizedBox(height: 10.0,),
                   Text('Remaining Count : ${widget.map['C_CNT']}', style: TextStyle(fontSize: 18, color: Colors.black),),
                  const SizedBox(height: 10.0,),
                   Text('Total Count : ${widget.map['T_CNT']}', style: TextStyle(fontSize: 18, color: Colors.black),),
                  const SizedBox(height: 10.0,),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [_buildButton("Cartridge", () => _navigateToCartridgeScreen(widget.device)), _buildButton("N/A", () {})],
                  ),
                  Row(
                    children: [_buildButton("Report Issue", () {}), _buildButton("N/A", () {})],
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