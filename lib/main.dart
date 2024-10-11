
import 'package:flutter/material.dart';
import 'package:poem_app/services/connectivity_service.dart';

import 'services/network_service.dart';




final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized


  NetworkService().initializeFirebase().then((_) {
    runApp(const MyApp());
  });

  // Initialize Firebase
  
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
      home: const ConnectivityService()
    );
  }
}

