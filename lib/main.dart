import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:poem_app/services/connectivity_service.dart';
import 'package:poem_app/services/network_service.dart';

import 'data/configs.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: 'poem-app',
        options: DefaultFirebaseOptions.currentPlatform);
    await Configs().load();
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: ConnectivityService(navigatorKey: navigatorKey),
    );
  }
}
