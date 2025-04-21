import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mfit/viewmodel/bluetooth_viewmodel.dart';
import 'package:provider/provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late BluetoothViewModel _bluetooth;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _bluetooth = context.read<BluetoothViewModel>();
      _bluetooth.startScan();
    });
  }

  @override
  void dispose() {
    _bluetooth.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bluetooth = context.watch<BluetoothViewModel>();
    final filteredResults = bluetooth.scanResults
        .where((r) => r.device.name.contains("MFIT"))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          if (filteredResults.isEmpty)
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (bluetooth.isScanning) ...[
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.yellow.shade600,
                        ),
                        padding: const EdgeInsets.all(40),
                        child: const Icon(Icons.bluetooth, size: 120, color: Colors.white),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Searching for nearby devices.\nPlease wait a moment.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.black),
                      ),
                    ] else
                      const Text(
                        "No devices found.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          if (filteredResults.isNotEmpty)
            Expanded(
              flex: 3,
              child: ListView.builder(
                itemCount: filteredResults.length,
                itemBuilder: (context, index) {
                  final result = filteredResults[index];
                  final device = result.device;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.bluetooth, color: Colors.blue),
                      title: Text(device.name.isNotEmpty ? device.name : "Unknown Device"),
                      subtitle: Text(device.id.toString()),
                      onTap: () async {
                        await bluetooth.connectToDevice(device);
                        FlutterBluePlus.stopScan();
                        if (context.mounted) Navigator.pop(context, device);
                      },
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: _buildCancelButton(
              context,
              () {
                FlutterBluePlus.stopScan();
                Navigator.pop(context);
              }
            ),
          ),
          const SizedBox(height: 30,),
        ],
      ),
    );
  }
}

Widget _buildCancelButton(BuildContext context, Function() onPressed) {
  return Container(
    width: 300,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      ),
      child: const Text('Cancel', style: TextStyle(fontSize: 16)),
    ),
  );
}

/*
Container(
              width: 250,
              child: OutlinedButton(
                onPressed: () {
                  FlutterBluePlus.stopScan();
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                ),
                child: const Text("Cancel", style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
            ),

 */

