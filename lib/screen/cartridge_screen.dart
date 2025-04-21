import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mfit/core/bluetooth/bluetooth_protocol.dart';
import 'package:mfit/screen/qr_scanner_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodel/bluetooth_viewmodel.dart';

class CartridgeScreen extends StatefulWidget {
  final BluetoothDevice device;
  const CartridgeScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<CartridgeScreen> createState() => _CartridgeScreenState();
}

class _CartridgeScreenState extends State<CartridgeScreen> {
  List<Map<String, String>> cartridgeHistory = [];

  Future<void> _loadCartridgeHistory(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'cartridge_history_$deviceId';

    List<String> historyList = prefs.getStringList(key) ?? [];

    setState(() {
      cartridgeHistory = historyList.map((entry) {
        final parts = entry.split('|');
        return {
          'code': parts[0],
          'date': parts.length > 1 ? parts[1] : 'Unknown'
        };
      }).toList();
    });
  }

  Future<void> _scanQRCode(BuildContext context) async {
    final scannedCode = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QRScannerScreen())
    );

    if(scannedCode != null) {
      final validationResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CartridgeCheckScreen(scannedCode: scannedCode, device: widget.device,),
        ),
      );

      if (validationResult != null && validationResult is bool) {
        if (validationResult) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartridgeRegistrationScreen(scannedCode: scannedCode, device: widget.device,),
              ),
            );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The cartridge code is invalid.')),
          );
        }
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadCartridgeHistory(widget.device.id.toString());
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('Cartridge Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20,),
              const Text(
                'Please select a method to enter the code.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // QR 스캔 버튼
              _buildButton(Icons.qr_code, 'Scan QR Code', () => _scanQRCode(context)),
              const SizedBox(height: 12),

              // 직접 입력 버튼
              _buildButton(Icons.edit, 'Manually Enter Code', null),
              const SizedBox(height: 50),

              const Text(
                'Cartridge code usage history',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // 테이블 헤더
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cartridge code',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Registration date',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: cartridgeHistory.length,
                  itemBuilder: (context, index) {
                    final item = cartridgeHistory[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['code']!, style: const TextStyle(fontSize: 14)),
                          Text(item['date']!, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 버튼 생성 함수
  Widget _buildButton(IconData icon, String text, Function()? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

enum QRCheckStatus { inProgress, success, failure }

class CartridgeCheckScreen extends StatefulWidget {
  final String scannedCode;
  final BluetoothDevice device;

  const CartridgeCheckScreen({super.key, required this.scannedCode, required this.device});

  @override
  State<CartridgeCheckScreen> createState() => _CartridgeCheckScreenState();
}

class _CartridgeCheckScreenState extends State<CartridgeCheckScreen> {
  QRCheckStatus _status = QRCheckStatus.inProgress;
  final BluetoothProtocol _bluetoothProtocol = BluetoothProtocol();
  StreamSubscription<List<int>>? _rxSubscription;

  Future<void> _sendSerialNumRequest(BluetoothViewModel bluetooth) async {
    final tx = bluetooth.txCharacteristic;
    final rx = bluetooth.rxCharacteristic;

    if(tx != null && rx != null) {
      await _rxSubscription?.cancel();

      String message = _bluetoothProtocol.createSerialNumberMessage();
      await tx.write(utf8.encode(message), withoutResponse: tx.properties.writeWithoutResponse);
      if(!rx.isNotifying) {
        await rx.setNotifyValue(true);
      }

      await _rxSubscription?.cancel();

      _rxSubscription = rx.lastValueStream.listen((data) {
        _bluetoothProtocol.onDataReceived(data);
      });
    }
  }

  void _handleResponse(String command, String data) async {
    print("Received Command: $command, Data: $data");

    if(!mounted) return;
    final bluetooth = context.read<BluetoothViewModel>();
    
    if(command == "SER") {
      final serialNumber = data.substring(0, 11);
      try {
        final docRef = FirebaseFirestore.instance.collection('qrcodes').doc(widget.scannedCode);
        final docSnap = await docRef.get();

        if (!docSnap.exists) {
          setState(() => _status = QRCheckStatus.failure);
          print('Not exists');
          return;
        }

        final data = docSnap.data();
        final int cartridgeCount = data?['cartridgeCount'] ?? 0;
        final String usedAt = data?['usedAt'] ?? "";

        if (cartridgeCount <= 0 || (usedAt != "" && usedAt != serialNumber)) {
          setState(() => _status = QRCheckStatus.failure);
          print('Error');
          return;
        }

        setState(() => _status = QRCheckStatus.success);

      } catch (e) {
        print("QR 유효성 검사 중 오류 발생: $e");
        setState(() => _status = QRCheckStatus.failure);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final bluetooth = context.read<BluetoothViewModel>();
      await bluetooth.connectToDevice(widget.device);
      await Future.delayed(const Duration(seconds: 3));
      _sendSerialNumRequest(bluetooth);
    });

    _bluetoothProtocol.onPacketReceived = (String command, String data) {
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

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData(_status);
    final iconColor = _getIconColor(_status);
    final message = _getMessage(_status);
    final circleColor = _getCircleColor(_status);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, size: 100, color: iconColor),
            ),
            const SizedBox(height: 30),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const Spacer(),
            _buildActionButton(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 버튼 구성
  Widget _buildActionButton() {
    switch (_status) {
      case QRCheckStatus.inProgress:
        return _buildOutlinedButton("Cancel", Colors.red, () {
          Navigator.pop(context, false);
        });
      case QRCheckStatus.success:
        return _buildFilledButton("Next", Colors.amber, () {
          Navigator.pop(context, true);
        });
      case QRCheckStatus.failure:
        return _buildOutlinedButton("Cancel", Colors.red, () {
          Navigator.pop(context, false);
        });
    }
  }

  // 버튼 스타일들
  Widget _buildOutlinedButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      width: 300,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildFilledButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      width: 300,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  // 상태별 텍스트
  String _getMessage(QRCheckStatus status) {
    switch (status) {
      case QRCheckStatus.inProgress:
        return 'Validating the cartridge code.\nPlease wait a moment...';
      case QRCheckStatus.success:
        return 'Cartridge code verification is complete';
      case QRCheckStatus.failure:
        return 'The cartridge code is invalid';
    }
  }

  // 상태별 아이콘
  IconData _getIconData(QRCheckStatus status) {
    switch (status) {
      case QRCheckStatus.inProgress:
        return Icons.dns; // 서버 아이콘
      case QRCheckStatus.success:
        return Icons.check;
      case QRCheckStatus.failure:
        return Icons.close;
    }
  }

  // 상태별 원 안 배경색
  Color _getCircleColor(QRCheckStatus status) {
    switch (status) {
      case QRCheckStatus.inProgress:
        return Colors.amber;
      case QRCheckStatus.success:
        return Colors.green;
      case QRCheckStatus.failure:
        return Colors.red;
    }
  }

  // 상태별 아이콘 색
  Color _getIconColor(QRCheckStatus status) {
    switch (status) {
      case QRCheckStatus.inProgress:
        return Colors.white;
      case QRCheckStatus.success:
        return Colors.white;
      case QRCheckStatus.failure:
        return Colors.white;
    }
  }
}

enum RegisterStatus { inProgress, success, failure }

class CartridgeRegistrationScreen extends StatefulWidget {
  final String scannedCode;
  final BluetoothDevice device;
  const CartridgeRegistrationScreen({super.key, required this.scannedCode, required this.device});

  @override
  State<CartridgeRegistrationScreen> createState() => _CartridgeRegistrationScreenState();
}

class _CartridgeRegistrationScreenState extends State<CartridgeRegistrationScreen> {
  RegisterStatus _status = RegisterStatus.inProgress;
  final BluetoothProtocol _bluetoothProtocol = BluetoothProtocol();
  StreamSubscription<List<int>>? _rxSubscription;

  Future<void> _saveCartridgeHistory(String deviceId, String cartridgeCode) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final historyEntry = "$cartridgeCode|$formattedDate";

    final key = 'cartridge_history_$deviceId'; // 장비별로 키 분리
    List<String> historyList = prefs.getStringList(key) ?? [];
    historyList.insert(0, historyEntry); // 최신 순

    await prefs.setStringList(key, historyList);
  }

  Future<void> _sendStateRequest(BluetoothViewModel bluetooth) async {
    final tx = bluetooth.txCharacteristic;
    final rx = bluetooth.rxCharacteristic;

    if(tx != null && rx != null) {
      await _rxSubscription?.cancel();

      String message = _bluetoothProtocol.createStateMessage();
      await tx.write(utf8.encode(message), withoutResponse: tx.properties.writeWithoutResponse);
      if(!rx.isNotifying) {
        await rx.setNotifyValue(true);
      }

      await _rxSubscription?.cancel();

      _rxSubscription = rx.lastValueStream.listen((data) {
        _bluetoothProtocol.onDataReceived(data);
      });
    }
  }

  void _handleResponse(String command, String data) async {
    print("Received Command: $command, Data: $data");

    if(!mounted) return;
    final bluetooth = context.read<BluetoothViewModel>();

    if (command == "STA") {
      final deviceID = data.substring(0, 11);
      final cartridgeIdStr = data.substring(11, 25);
      final cartridgeCount = data.substring(25, 31);

      final oldCartridgeID = cartridgeIdStr;
      final oldRemaining = int.tryParse(cartridgeCount) ?? 0;

      print(oldCartridgeID);

      try {
        if(oldCartridgeID != "AAAAAAAAAAAAAA") {
          final docRef1 = FirebaseFirestore.instance.collection('qrcodes').doc(
              oldCartridgeID);
          await docRef1.update({
            'cartridgeCount': oldRemaining,
          });
        }
        final newCode = widget.scannedCode;
        final docRef2 = FirebaseFirestore.instance.collection('qrcodes').doc(newCode);
        final docSnap = await docRef2.get();

        final snapData = docSnap.data();
        final int remaining = snapData?['cartridgeCount'] ?? 0;
        final tx = bluetooth.txCharacteristic;

        if(tx != null) {
          final message = _bluetoothProtocol.createCartridgeRegistrationMessage(newCode, remaining);
          final bytes = utf8.encode(message); // 문자열을 바이트로 인코딩

          const mtu = 20; // BLE 기본 MTU 크기 제한
          for (var i = 0; i < bytes.length; i += mtu) {
            final chunk = bytes.sublist(i, i + mtu > bytes.length ? bytes.length : i + mtu);
            await tx.write(
              chunk,
              withoutResponse: tx.properties.writeWithoutResponse,
            );
            await Future.delayed(Duration(milliseconds: 20)); // 장치가 처리할 시간 여유
          }

          await docRef2.update({
            'usedAt': deviceID,
          });

          setState(() => _status = RegisterStatus.success);
          await _saveCartridgeHistory(widget.device.id.toString(), widget.scannedCode);
        } else {
          setState(() => _status = RegisterStatus.failure);
        }
      } catch(e) {
        print("Firebase Update Fail: $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final bluetooth = context.read<BluetoothViewModel>();
      await bluetooth.connectToDevice(widget.device);
      await Future.delayed(const Duration(seconds: 3));
      _sendStateRequest(bluetooth);
    });

    _bluetoothProtocol.onPacketReceived = (String command, String data) {
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
  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData(_status);
    final iconColor = _getIconColor(_status);
    final message = _getMessage(_status);
    final circleColor = _getCircleColor(_status);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, size: 100, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const Spacer(),
            _buildActionButton(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 버튼 구성
  Widget _buildActionButton() {
    switch (_status) {
      case RegisterStatus.inProgress:
        return _buildOutlinedButton("Cancel", Colors.red, () {
          Navigator.pop(context, false);
        });
      case RegisterStatus.success:
        return _buildFilledButton("Done", Colors.amber, () {
          Navigator.pop(context, true);
        });
      case RegisterStatus.failure:
        return _buildOutlinedButton("Cancel", Colors.red, () {
          Navigator.pop(context, false);
        });
    }
  }

  // 버튼 스타일들
  Widget _buildOutlinedButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      width: 300,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildFilledButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      width: 300,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  // 상태별 텍스트
  String _getMessage(RegisterStatus status) {
    switch (status) {
      case RegisterStatus.inProgress:
        return 'Registering the cartridge\nPlease wait a moment...';
      case RegisterStatus.success:
        return 'Cartridge registration is complete.';
      case RegisterStatus.failure:
        return 'Cartridge registration failed.';
    }
  }

  // 상태별 아이콘
  IconData _getIconData(RegisterStatus status) {
    switch (status) {
      case RegisterStatus.inProgress:
        return Icons.dns; // 서버 아이콘
      case RegisterStatus.success:
        return Icons.check;
      case RegisterStatus.failure:
        return Icons.close;
    }
  }

  // 상태별 원 안 배경색
  Color _getCircleColor(RegisterStatus status) {
    switch (status) {
      case RegisterStatus.inProgress:
        return Colors.amber;
      case RegisterStatus.success:
        return Colors.green;
      case RegisterStatus.failure:
        return Colors.red;
    }
  }

  // 상태별 아이콘 색
  Color _getIconColor(RegisterStatus status) {
    switch (status) {
      case RegisterStatus.inProgress:
        return Colors.white;
      case RegisterStatus.success:
        return Colors.white;
      case RegisterStatus.failure:
        return Colors.white;
    }
  }
}





