import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mfit/screen/login_screen.dart';
import 'package:mfit/viewmodel/bluetooth_viewmodel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  requestBluetoothPermissions();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothViewModel()),
      ],
      child: const MyApp()
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

void requestBluetoothPermissions() async {
  if (await Permission.bluetoothScan.request().isGranted &&
      await Permission.bluetoothConnect.request().isGranted &&
      await Permission.location.request().isGranted &&
      await Permission.camera.request().isGranted) {
    print("Bluetooth permission granted.");
  } else {
    print("Bluetooth permission denied.");
  }
}

