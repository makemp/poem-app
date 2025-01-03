import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/configs.dart';
import '../main.dart';
import '../services/network_service.dart';
import '../services/notification_service.dart';
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
              Center(child:
              Row(
                children: [
                  const SizedBox(width: 8),
              Center(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const PoemScreen()));
                    },
                    child: Text(Configs().firstScreenGet('button_text')),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.brown, backgroundColor: Colors.white, // White text and icon color
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      textStyle: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ),
              ),

                  const SizedBox(width: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(Configs().firstScreenGet('coffee_url'))),
                  icon: Icon(
                    Icons.local_cafe, // Coffee icon
                    color: Colors.brown, // Icon color
                    size: 20.0, // Icon size
                  ),
                  label: Text(
                    Configs().firstScreenGet('coffee_text'),
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.brown, // Text color
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.pink, backgroundColor: Colors.white, // White text and icon color
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    textStyle: TextStyle(fontSize: 16.0),
                  ),
                ),
                ),
              ]
              )
              ),
            ],
          ),
        ),
        floatingActionButton: _fullPotential ? const AddPoemWidget() : LockWidget(unlockFullPotential: _unlockFullPotential), // Add lock icon widget here
      );
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
     //if (defaultTargetPlatform == TargetPlatform.android) {
      // if (await Permission.notification.isDenied) {
      //   await Permission.notification.request();
      // }
    // }

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
     }
   }

   // Background message handler must be a top-level function




    // Handle background and terminated notifications
  }

