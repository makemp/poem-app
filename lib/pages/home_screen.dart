import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sign_in_button/sign_in_button.dart';

import '../data/configs.dart';
import '../main.dart';
import '../services/network_service.dart';
import '../services/notification_service.dart';
import '../services/version_check_service.dart';
import '../widgets/add_poem_widget.dart';
import '../widgets/lock_widget.dart';
import 'poem_screen.dart';
import '../services/auth_service.dart';

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
        // The leading icon is automatically added when a Drawer is present
      ),
      drawer: _buildDrawer(), // Add the Drawer here
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
                      'assets/images/rose.webp', // Replace with your image asset path
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PoemScreen()),
                    );
                  },
                  child: Text(Configs().firstScreenGet('button_text')),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _fullPotential
          ? const AddPoemWidget()
          : LockWidget(unlockFullPotential: _unlockFullPotential), // Add lock icon widget here
    );
  }

  // Build the Drawer widget
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero, // Remove any default padding
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.login),
            title: Text('Log in'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              _showLoginDialog();
            },
          ),
          // Add more drawer items here if needed
        ],
      ),
    );
  }

  // Show the enhanced login dialog
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          child: _loginDialogContent(context),
        );
      },
    );
  }

Widget _loginDialogContent(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(16.0),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min, // To make the dialog compact
      children: <Widget>[
        Text(
          'Log in',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          'Choose a login method',
          style: TextStyle(
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: 24.0),
        // Google Login Button using sign_in_button package
        SignInButton(
          Buttons.google,
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
            _loginWithGoogle();
          },
        ),
        const SizedBox(height: 16.0),
        // Apple Login Button using sign_in_button package
        SignInButton(
          Buttons.apple,
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
            _loginWithApple();
          },
        ),
      ],
    ),
  );
}

  // Placeholder function for Google login
  void _loginWithGoogle() {
    // Implement your Google login logic here
    AuthService.instance.signInWithGoogle();
  }

  // Placeholder function for Apple login
  void _loginWithApple() {
    // Implement your Apple login logic here
   AuthService.instance.signInWithApple();
  }

  void _initializeFCM() async {
    _firebaseMessaging = FirebaseMessaging.instance;

    // Request notification permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Request POST_NOTIFICATIONS permission for Android 13+
    // Uncomment and implement if needed
    /*
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
    */

    // Proceed if permissions are granted
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await NotificationService.initialize();

      // Subscribe to 'all' topic
      await _firebaseMessaging.subscribeToTopic('all');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        try {
          if (message.notification != null) {
            await NotificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: message.notification!.title ?? 'New Poem',
              body: message.notification!.body ?? 'A new poem has been added.',
              payload: message.data['payload'] ?? '',
            );
          }
        } catch (e) {
          // Handle error
        }
      });

      // Check for initial message when the app is launched from a terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState!.pushReplacement(
            MaterialPageRoute(
              builder: (context) => PoemScreen(),
            ),
          );
        });
      }
    } else {
      // Handle permissions not granted
    }
  }

  // Background message handler must be a top-level function
  // Define it outside of the _HomeScreenState class
}

// If you need to handle background messages, define this outside the class
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   // Handle the message
// }
