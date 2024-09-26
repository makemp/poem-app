import 'dart:io';

import 'package:flutter/material.dart';
import 'package:poem_app/widgets/add_poem_widget.dart';
import 'package:poem_app/widgets/lock_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/poem_screen.dart';
import 'services/network_service.dart';



class DevelopmentHttpConfig extends HttpOverrides {
  DevelopmentHttpConfig({
    required this.certExclusionDomains,
    this.iosProxyHost = '127.0.0.1',
    this.androidProxyHost = '10.0.2.2',
    this.proxyPort,
  });

  /// Proxy used for android
  /// Defaults to the 10.0.2.x network
  String androidProxyHost;

  /// Proxy used for IOS because it uses the host network. defaults to 127.0.0.1
  /// Android has its own network
  String iosProxyHost;

  /// list of domains we exclude from cert check
  List<String> certExclusionDomains;

  /// proxyPort != null means setup the proxy if isAndroid or isIOS
  int? proxyPort;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final exclusion = super.createHttpClient(context);

    // ignore self signed certs in these domains
    exclusion.badCertificateCallback = (cert, host, port) =>
        certExclusionDomains.any((element) => host.endsWith(element));

    if (proxyPort != null) {
      if (Platform.isAndroid) {
        exclusion.findProxy = (url) => 'PROXY $androidProxyHost:$proxyPort';
      }
      if (Platform.isIOS) {
        exclusion.findProxy = (url) => 'Proxy $iosProxyHost:$proxyPort';
      }
    }
    return exclusion;
  }
}



void main() async{
   HttpOverrides.global = DevelopmentHttpConfig(certExclusionDomains: ['firebaseinstallations.googleapis.com'], proxyPort: 8080);

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
   final String magicPassword = 'magic';
   bool _fullPotential = false;

  void _unlockFullPotential(String str) {
    bool fullPotential = str == magicPassword;
    setState(() {
      _fullPotential = fullPotential;
    });
  }

  Future<void> _unlockFullPotentialOnLoad() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _unlockFullPotential(prefs.getString('user_input').toString());
  }



  @override
  void initState() {
    super.initState();
    
    _unlockFullPotentialOnLoad();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Poezja Romany Lemańskiej'),
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
                      const Text(
                        'Romana Lemańska',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Witaj w miejscu, gdzie publikuję moją poezję. Znajdziesz tutaj modlitwy, fraszki, przygody krasnalka Konotopka oraz inne utwory.',
                          style: TextStyle(fontSize: 16),
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
                    child: const Text('Czytaj wiersze'),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _fullPotential ? const AddPoemWidget() : LockWidget(unlockFullPotential: _unlockFullPotential), // Add lock icon widget here
      ),
    );
  }
}

