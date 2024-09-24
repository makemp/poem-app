import 'package:flutter/material.dart';
import 'package:poem_app/widgets/add_poem_widget.dart';
import 'package:poem_app/widgets/lock_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/poem_screen.dart';

void main() {
  runApp(const MyApp());
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

    // Fetch poems for the initial date
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
                          MaterialPageRoute(builder: (context) => PoemScreen()));
                    },
                    child: const Text('Czytaj wiersze'),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _fullPotential ? AddPoemWidget() : LockWidget(unlockFullPotential: _unlockFullPotential), // Add lock icon widget here
      ),
    );
  }
}

