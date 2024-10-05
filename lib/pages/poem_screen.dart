import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/configs.dart';
import '../data/poem.dart';
import '../widgets/heart_widget.dart';
import '../widgets/poem_tile.dart';
import '../services/poems_service.dart';

class PoemScreen extends StatefulWidget {
  const PoemScreen({super.key});

  @override
  _PoemScreenState createState() => _PoemScreenState();
}

class _PoemScreenState extends State<PoemScreen> {
  DateTime _selectedDate = DateTime.now(); // Initialize with the current date
  List<Poem> _poems = []; // List to hold poems for the selected date

  @override
  void initState() {
    super.initState();
    // Fetch poems for the initial date
    _fetchPoemsForDate(_selectedDate);
  }

  // Fetch poems for a specific date and update the state
  void _fetchPoemsForDate(DateTime date) async {
    List<Poem> fetchedPoems = await PoemsService().display(date);
    setState(() {
      _poems = fetchedPoems; // Update the poems list
    });
  }

  // Function to handle date picking
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked; // Update the selected date
      });
      _fetchPoemsForDate(picked); // Fetch poems for the new date
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back button
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        title: GestureDetector(
          onTap: () => _pickDate(context), // Open the date picker when tapped
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Add some padding
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 187, 79, 79), // Background color of the date text
              borderRadius: BorderRadius.circular(8), // Rounded corners for the background
            ),
            child: Text(
              '${Configs().browsePoemsScreenGet('date_picker_prompt')} ${DateFormat('yyyy-MM-dd').format(_selectedDate)}', // Display "Poems for <date>"
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white, // Text color inside the gesture detector
              ),
            ),
          ),
        ),
        centerTitle: true, // Center the title in the AppBar
      ),
      body: Center(
        child: _poems.isNotEmpty
            ? PoemTile(poems: _poems, initialIndex: _poems.length - 1) // Pass the poems list to PoemTile
            : Text(Configs().browsePoemsScreenGet('no_poems')), // Show message if no poems
      ),
    );
  }
}
