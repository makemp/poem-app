import 'package:flutter/material.dart';
import '../services/poems_service.dart';

class AddPoemPage extends StatefulWidget {
  const AddPoemPage({super.key});

  @override
  _AddPoemPageState createState() => _AddPoemPageState();
}

class _AddPoemPageState extends State<AddPoemPage> {
  final TextEditingController _poemController = TextEditingController(); // Controller for poem input

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj wiersz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tekst wiersza:',
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
                PoemsService().publish(_poemController.text);
                // Pass the poem back to the previous screen
                Navigator.pop(context, _poemController.text); // Return poem text
              },
              child: const Text('Opublikuj'),
            ),
          ],
        ),
      ),
    );
  }
}
