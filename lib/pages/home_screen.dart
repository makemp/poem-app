import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../data/configs.dart';
import '../services/network_service.dart';
import '../services/version_check_service.dart';
import '../widgets/add_poem_widget.dart';
import '../widgets/lock_widget.dart';
import 'poem_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
   bool _fullPotential = false;
   late FirebaseMessaging _firebaseMessaging;

  Future<void> _unlockFullPotential() async {
    bool? resp = await NetworkService().verifyMagicWord();
    if (!mounted) return;
    if (resp == true) {
      setState(() {
        _fullPotential = true;
      });
    }

  }

  @override
  void initState() {
    super.initState();
    VersionCheckService().checkAppVersion();
    _unlockFullPotential();
    _initializeFCM();
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(Configs().firstScreenGet('top_title')),
        ),
        body: Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 16, top: 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      // Author Image
                      Image.asset(
                        'images/rose.webp', // Replace with your image asset path
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 8), // Space between image and text
                      Text(
                        Configs().firstScreenGet('photo_title'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Configs().firstScreenGet('description'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const PoemScreen()));
                    },
                    child: Text(Configs().firstScreenGet('button_text')),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _fullPotential ? const AddPoemWidget() : LockWidget(unlockFullPotential: _unlockFullPotential), // Add lock icon widget here
      );
  }

  void _initializeFCM() async {
     if (TargetPlatform.android != defaultTargetPlatform || TargetPlatform.iOS != defaultTargetPlatform) {
       return;
     }

    _firebaseMessaging = FirebaseMessaging.instance;

    // Request permission for iOS notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Subscribe to 'all' topic to receive global notifications
    await _firebaseMessaging.subscribeToTopic('all');

    // Listen for foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a notification in the foreground: ${message.notification?.title}');
    });

    // Handle background and terminated notifications
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked: ${message.notification?.title}');
    });
  }
}
