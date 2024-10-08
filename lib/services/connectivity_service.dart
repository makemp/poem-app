import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:poem_app/pages/home_screem.dart';
import '../main.dart';

class ConnectivityService extends StatefulWidget {
  const ConnectivityService({super.key});

  @override
  State<ConnectivityService> createState() => _ConnectivityServiceState();
}

class _ConnectivityServiceState extends State<ConnectivityService> {
late final StreamSubscription<InternetStatus> _subscription;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    // Listen for internet status changes
    _subscription = InternetConnection().onStatusChange.listen((status) {
      if (status == InternetStatus.connected) {
        setState(() {
          _isConnected = true;
        });
      } else {
        setState(() {
          _isConnected = false;
        });
      }
    });

    // If already connected, navigate to HomeScreen directly
    InternetConnection().hasInternetAccess.then((hasConnection) {
      if (hasConnection) {
        _navigateToHome();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      // If connected, navigate to the home screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToHome();
      });
      return const SizedBox(); // Empty widget as the transition will happen immediately
    }

    // If not connected, show No Internet screen
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              color: Colors.red,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              "Brak połączenie z internetem.",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Proszę sprawdzić połączenie i spróbować ponownie.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
