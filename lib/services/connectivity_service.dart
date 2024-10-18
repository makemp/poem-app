import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:poem_app/pages/home_screen.dart';

class ConnectivityService extends StatefulWidget {
  /// Navigator key to handle navigation
  final GlobalKey<NavigatorState> navigatorKey;

  const ConnectivityService({
    Key? key, required this.navigatorKey,
  }) : super(key: key);

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
    // Optionally, check the initial connection status
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    bool hasConnection = await InternetConnection().hasInternetAccess;
    if (hasConnection) {
      _navigateToHome(); // Navigate if already connected
    }
  }

  void _navigateToHome() {
    // Use the navigatorKey to perform navigation
    widget.navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: InternetConnection().hasInternetAccess,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while checking connectivity
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData && snapshot.data == true) {
          // Connected, navigation handled in initState and listener
          return const SizedBox.shrink(); // Empty widget as navigation happens
        } else {
          // Not connected, show No Internet screen
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: NoInternetScreen(navigatorKey: widget.navigatorKey),
              ),
            ),
          );
        }
      },
    );
  }
}

class NoInternetScreen extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const NoInternetScreen({
    required this.navigatorKey,
    Key? key,
  }) : super(key: key);

  void _retryConnection(BuildContext context) async {
    bool hasConnection = await InternetConnection().hasInternetAccess;
    if (hasConnection) {
      // Navigate to HomeScreen using the navigatorKey
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Show a snackbar or dialog informing the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brak połączenia z internetem. Proszę spróbować ponownie.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
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
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _retryConnection(context),
          child: const Text("Spróbuj ponownie"),
        ),
      ],
    );
  }
}
