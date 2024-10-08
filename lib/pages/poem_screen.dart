import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/configs.dart';
import '../data/poem.dart';
import '../widgets/poem_tile.dart';
import '../services/poems_service.dart';
import '../services/network_service.dart'; // Assuming NetworkService is in services folder

class PoemScreen extends StatefulWidget {
  const PoemScreen({super.key});

  @override
  _PoemScreenState createState() => _PoemScreenState();
}

class _PoemScreenState extends State<PoemScreen> {
  DateTime _selectedDate = DateTime.now(); // Initialize with the current date
  List<Poem> _poems = []; // List to hold poems for the selected date
  TextEditingController _searchController = TextEditingController(); // Controller for search field
  bool _isSearching = false; // To track if we are in search mode

  @override
  void initState() {
    super.initState();
    // Fetch poems for the initial date
    _fetchPoemsForDate(_selectedDate);

    // Add listener to search input
    _searchController.addListener(() {
      if (_searchController.text.length >= 5) {
        _searchPoems(_searchController.text);
      } else if (_searchController.text.isEmpty) {
        _fetchPoemsForDate(_selectedDate); // Reset to original poems when search is cleared
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose controller when the widget is disposed
    super.dispose();
  }

  // Fetch poems for a specific date and update the state
  void _fetchPoemsForDate(DateTime date) async {
    List<Poem> fetchedPoems = await PoemsService().display(date);
    setState(() {
      _poems = fetchedPoems; // Update the poems list
      _isSearching = false; // Reset search state
    });
  }

  // Search poems based on query
  void _searchPoems(String query) async {
    List<Poem> searchedPoems = await NetworkService().search(query); // Assume search is implemented in NetworkService
    setState(() {
      print(searchedPoems);
      _poems = searchedPoems; // Update the poems list with search results
      _isSearching = true; // Indicate that we are in search mode
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
        actions: [
          // Add search field in the AppBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: 200,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Wpisz 4 lub więcej znaków...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: _poems.isNotEmpty
            ? PoemTile(poems: _poems, initialIndex: _poems.length - 1) // Pass the poems list to PoemTile
            : Text(Configs().browsePoemsScreenGet(_isSearching ? 'no_search_results' : 'no_poems')), // Show message if no poems
      ),
    );
  }
}
