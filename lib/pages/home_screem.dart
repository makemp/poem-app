import 'package:flutter/material.dart';

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

  Future<void> _unlockFullPotential() async {
    bool? resp = await NetworkService().verifyMagicWord();
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
                        style: TextStyle(
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
}
