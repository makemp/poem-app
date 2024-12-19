import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  final bool openDrawerOnLoad;

  const HomeScreen({Key? key, this.openDrawerOnLoad = false}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final scaffoldKey =  GlobalKey<ScaffoldState>();
  bool _fullPotential = false;
  late FirebaseMessaging _firebaseMessaging;
  late StreamSubscription<User?> _authSubscription;

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

    // Listen to auth state changes and rebuild UI when user logs in/out
    _authSubscription = AuthService.instance.authStateChanges.listen((user) {
      if (!mounted) return; 
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.openDrawerOnLoad) {
        scaffoldKey.currentState?.openDrawer();
      }
    });
  }


    @override
  void dispose() {
    _authSubscription.cancel(); // Cancel the subscription
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(Configs().firstScreenGet('top_title')),
      ),
      drawer: _buildDrawer(),
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
                    Image.asset(
                      'assets/images/rose.webp',
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 8),
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
                  child: Text(
                    Configs().firstScreenGet('description'),
                    style: const TextStyle(fontSize: 16),
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
          : LockWidget(unlockFullPotential: _unlockFullPotential),
    );
  }

  Widget _buildDrawer() {
  return Drawer(
    child: StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        // The snapshot will update whenever the user changes (sign in/out)
        bool isLoggedIn = snapshot.hasData && snapshot.data != null;
        
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            if (isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Wyloguj się"),
                onTap: () async {
                  Navigator.pop(context); // close drawer
                  await AuthService.instance.signOut();
                  // The drawer updates automatically via StreamBuilder
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Zaloguj się'),
                onTap: () {
                  Navigator.pop(context);
                  _showLoginDialog();
                },
              ),
          ],
        );
      },
    ),
  );
}



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
        mainAxisSize: MainAxisSize.min, 
        children: <Widget>[
          const Text(
            'Zaloguj się',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24.0),
          defaultTargetPlatform == TargetPlatform.android ? SignInButton(
            Buttons.google,
            onPressed: () async {
              Navigator.of(context).pop();
              await AuthService.instance.signInWithGoogle();
              // No need to manually call setState(), listener will do it
            },
          ) :
          const SizedBox(height: 16.0),
          SignInButton(
            Buttons.apple,
            onPressed: () async {
              Navigator.of(context).pop();
              await AuthService.instance.signInWithApple();
              // No need to manually call setState(), listener will do it
            },
          ),
        ],
      ),
    );
  }

  void _initializeFCM() async {
    _firebaseMessaging = FirebaseMessaging.instance;
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await NotificationService.initialize();
      await _firebaseMessaging.subscribeToTopic('all');

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

      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState!.pushReplacement(
            MaterialPageRoute(
              builder: (context) => const PoemScreen(),
            ),
          );
        });
      }
    } else {
      // Handle permissions not granted
    }
  }
}
