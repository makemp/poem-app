import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:poem_app/pages/home_screen.dart';

class ConnectivityService extends StatefulWidget {
  const ConnectivityService({super.key});

  @override
  State<ConnectivityService> createState() => _ConnectivityServiceState();
}

class _ConnectivityServiceState extends State<ConnectivityService> {
  late final StreamSubscription<InternetStatus> _subscription;

  @override
  void initState() {
    super.initState();
    // Listen for internet status changes
    _subscription = InternetConnection().onStatusChange.listen((status) {
      if (status == InternetStatus.connected) {
        _navigateToHome(); // Navigate immediately when connected
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _navigateToHome() {
    // Check if the widget is still mounted before navigating
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: InternetConnection().hasInternetAccess,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While checking for connection, show nothing
          return const SizedBox();
        } else if (snapshot.hasData && snapshot.data == true) {
          // Connected, navigate to HomeScreen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToHome();
          });
          return const SizedBox(); // Empty widget as navigation happens
        } else {
          // Not connected, show No Internet screen
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
                    "Brak połączenia z internetem.",
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
      },
    );
  }
}
