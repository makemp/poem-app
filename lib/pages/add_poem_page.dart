import 'package:flutter/material.dart';
import '../data/configs.dart';
import '../services/poems_service.dart';

class AddPoemPage extends StatefulWidget {
  const AddPoemPage({super.key});

  @override
  _AddPoemPageState createState() => _AddPoemPageState();
}

class _AddPoemPageState extends State<AddPoemPage> {
  final TextEditingController _poemController = TextEditingController(); // Controller for poem input

  // Function to show the green popup after publishing the poem
  void _showSuccessPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent the dialog from being dismissed by clicking outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.green, // Green background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                  Configs().addPoemScreenGet('success_text'),
                  style: const TextStyle(
                    color: Colors.white, // White text color for contrast
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the popup
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // White button with green text
                  ),
                  child:  Text(
                    Configs().addPoemScreenGet('success_text_close'),
                    style: const TextStyle(
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Configs().addPoemScreenGet('title')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                Configs().addPoemScreenGet('prompt'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Poem input field
              TextField(
                controller: _poemController,
                decoration: const InputDecoration(
                  labelText: '',
                  border: OutlineInputBorder(),
                ),
                maxLines: 18, // Allow multiline input for poem
              ),
              const SizedBox(height: 16),
              // Confirm button
              ElevatedButton(
                onPressed: () {
                  // Publish the poem
                  PoemsService().publish(_poemController.text);

                  // Clear the text field after publishing
                  _poemController.clear();

                  // Show the green success popup
                  _showSuccessPopup(context);
                },
                child: Text(Configs().addPoemScreenGet('button_text')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
