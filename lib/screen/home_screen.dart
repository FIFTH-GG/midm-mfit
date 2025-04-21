import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mfit/screen/setting_screen.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_confirmation_screen.dart';
import 'device_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BluetoothDevice> connectedDevices = [];
  Map<String, BluetoothConnectionState> deviceConnectionStatus = {};
  final List<StreamSubscription<BluetoothConnectionState>> _subscriptions = [];
  Map<String, String> deviceNameMap = {};
  Map<String, String> deviceDateMap = {};

  @override
  void initState() {
    super.initState();
    _restoreConnectedDevices();
  }

  Future<void> _restoreConnectedDevices() async {
    List<BluetoothDevice> devices = await loadConnectedDevices();
    setState(() {
      connectedDevices = devices;
    });

    for (BluetoothDevice device in devices) {
      final subscription = device.connectionState.listen((state) {
        deviceConnectionStatus[device.id.toString()] = state;
        if (mounted) setState(() {});
      });
      _subscriptions.add(subscription);
    }
  }

  void _navigateToScanScreen() async {
    final BluetoothDevice? newDevice = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanScreen()),
    );

    if (newDevice != null && !connectedDevices.contains(newDevice)) {
      setState(() {
        connectedDevices.add(newDevice);
      });

      await saveConnectedDevice(newDevice);

      final subscription = newDevice.connectionState.listen((state) {
        deviceConnectionStatus[newDevice.id.toString()] = state;
        if (mounted) setState(() {});
      });
      _subscriptions.add(subscription);
    }
  }

  void _navigateToConfirmationScreen(BluetoothDevice device) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceConfirmationScreen(device: device)),
    );

    if(result != null && result is Map<String, dynamic>) {
      if(result['remove'] == true) {

      } else if (result['result']) {
        String name = device.name.isNotEmpty
            ? device.name
            : (deviceNameMap[device.id.toString()] ?? "Unknown Device");

        final deviceScreenResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceScreen(device: device, name: name, date: deviceDateMap[device.id.toString()] ?? "Unknown", map: result),
          ),
        );

        if (deviceScreenResult != null &&
            deviceScreenResult is Map<String, dynamic> &&
            deviceScreenResult['removed'] == true) {
          // 삭제된 경우 리스트 갱신
          _restoreConnectedDevices();
        }
      } else {

      }
    } else {

    }
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 250,
            color: Colors.amber,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Center(
                  child: Image.asset(
                    'assets/images/logo_white.png',
                    height: 120,
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Welcome to M-FIT",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SettingScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "My Devices",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: connectedDevices.isEmpty
                        ? const Center(child: Text("No devices connected."))
                        : ListView.builder(
                      itemCount: connectedDevices.length,
                      itemBuilder: (context, index) {
                        BluetoothDevice device = connectedDevices[index];
                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Image.asset(
                              'assets/images/device.png',
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                            ),
                            title: Text(device.name.isNotEmpty ? device.name : (deviceNameMap[device.id.toString()] ?? "Unknown Device")),
                            subtitle: Text(device.id.toString()),
                            trailing: Text(
                              deviceDateMap[device.id.toString()] ?? "Unknown",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            onTap: () => _navigateToConfirmationScreen(device),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: FloatingActionButton(
              onPressed: _navigateToScanScreen,
              backgroundColor: Colors.amber,
              child: const Icon(Icons.add, size: 36, color: Colors.black),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> saveConnectedDevice(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList('connected_devices') ?? [];

    final now = DateTime.now();
    final formattedDate = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final entry = "${device.id}|${device.name}|$formattedDate";
    bool alreadyExists = savedList.any((e) => e.startsWith(device.id.toString()));

    if (!alreadyExists) {
      savedList.add(entry);
      await prefs.setStringList('connected_devices', savedList);
      debugPrint("[저장됨] connected_devices: $savedList");

      deviceNameMap[device.id.toString()] = device.name;
      deviceDateMap[device.id.toString()] = formattedDate;
    }
  }


  Future<List<BluetoothDevice>> loadConnectedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> entries = prefs.getStringList('connected_devices') ?? [];
    debugPrint("[불러옴] connected_devices: $entries");

    List<BluetoothDevice> devices = [];
    for (String entry in entries) {
      final parts = entry.split('|');
      final id = parts[0];
      final name = parts.length > 1 ? parts[1] : "";
      final date = parts.length > 2 ? parts[2] : "Unknown";
      final device = BluetoothDevice.fromId(id);
      deviceNameMap[id] = name;
      deviceDateMap[id] = date;
      devices.add(device);
    }
    return devices;
  }

}
