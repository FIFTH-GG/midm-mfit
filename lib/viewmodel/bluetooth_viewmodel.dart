import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothViewModel extends ChangeNotifier {
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  bool _isScanning = false;
  bool _isBluetoothOn = false;

  // Getters
  BluetoothCharacteristic? get txCharacteristic => _txCharacteristic;
  BluetoothCharacteristic? get rxCharacteristic => _rxCharacteristic;
  List<ScanResult> get scanResults => _scanResults;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  BluetoothConnectionState get connectionState => _connectionState;
  bool get isScanning => _isScanning;
  bool get isBluetoothOn => _isBluetoothOn;

  BluetoothViewModel() {
    _monitorBluetoothState();
  }

  // Bluetooth adapter 상태 구독
  void _monitorBluetoothState() {
    FlutterBluePlus.adapterState.listen((state) {
      _isBluetoothOn = state == BluetoothAdapterState.on;
      notifyListeners();
    });
  }

  // 스캔 시작
  Future<void> startScan() async {
    if (_isScanning) return;
    _isScanning = true;
    _scanResults = [];
    notifyListeners();

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
    });
  }

  // 스캔 중지
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  // 디바이스 연결
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (device.isConnected == true) return;
    await device.connect();
    _connectedDevice = device;

    final services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase() == 'FFF0') {
        for (var char in service.characteristics) {
          if (char.uuid.toString().toUpperCase() == 'FFF2') {
            _txCharacteristic = char;
          }
          if (char.uuid.toString().toUpperCase() == 'FFF1') {
            _rxCharacteristic = char;
          }
        }
      }
    }

    notifyListeners();

    // 연결 상태 구독
    device.connectionState.listen((state) {
      _connectionState = state;
      notifyListeners();
    });
  }

  // 디바이스 연결 해제
  Future<void> disconnectFromDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _connectionState = BluetoothConnectionState.disconnected;
      notifyListeners();
    }
  }
}
