import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:poem_app/services/connectivity_service.dart';

import 'package:poem_app/services/notification_service.dart';

import 'data/configs.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Required for plugin initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the notification service
  await NotificationService.initialize();

  // Display the notification
  if (message.notification != null) {
    await NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.notification!.title ?? 'New Poem',
      body: message.notification!.body ?? 'A new poem has been added.',
      payload: 'navigate_to_poem_screen',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized

    await Firebase.initializeApp(
        name: kIsWeb ? '[DEFAULT]' : 'my-poem-app',
        options: DefaultFirebaseOptions.currentPlatform);
    await Configs().load();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize NotificationService
    await NotificationService.initialize();
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
