// Widget for lock icon and input dialog
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockWidget extends StatefulWidget {
  final Function unlockFullPotential;
  const LockWidget({super.key, required this.unlockFullPotential});

  @override
  _LockWidgetState createState() => _LockWidgetState();
}

class _LockWidgetState extends State<LockWidget> {
  bool _isUnlocked = false; // Controls the visibility of the input form
  final TextEditingController _inputController = TextEditingController(); // Input controller


 

  // Function to save the input text to persistent storage
  Future<void> _saveInput() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_input', _inputController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zapisane')),
    );

    

    setState(() {
      _isUnlocked = false; // Hide input form after saving
    });
    widget.unlockFullPotential(_inputController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isUnlocked) // Display the input form when unlocked
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      labelText: 'Fraza',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveInput, // Call function to save input
                  child: const Text('Potwierdź'),
                ),
              ],
            ),
          ),
        // Lock/Unlock button
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _isUnlocked = !_isUnlocked; // Toggle between locked and unlocked state
            });
          },
          child: Icon(_isUnlocked ? Icons.lock_open : Icons.lock),
        ),
      ],
    );
  }
}
