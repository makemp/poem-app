import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart'; // Import the package
import '../data/configs.dart';
import '../data/poem.dart';
import '../services/poems_service.dart';
import '../services/network_service.dart';

class PoemScreen extends StatefulWidget {
  const PoemScreen({super.key});

  @override
  _PoemScreenState createState() => _PoemScreenState();
}

class _PoemScreenState extends State<PoemScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Poem> _poems = [];
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Replace ScrollController with ItemScrollController and ItemPositionsListener
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _fetchPoemsForDate(_selectedDate);

    _searchController.addListener(() {
      String query = _searchController.text;
      if (query.length >= 4) {
        _searchPoems(query);
        setState(() {
          _isSearching = true;
        });
      } else if (query.isEmpty) {
        _fetchPoemsForDate(_selectedDate);
        setState(() {
          _isSearching = false;
        });
      } else {
        // Do nothing; allow the user to continue typing
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch poems for a specific date and update the state
  void _fetchPoemsForDate(DateTime date) async {
    List<Poem> fetchedPoems = await PoemsService().display(date);
    setState(() {
      _poems = fetchedPoems;
      _isSearching = false;
    });
    // Scroll to the last item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastItem();
    });
  }

  // Search poems based on query
  void _searchPoems(String query) async {
    List<Poem> searchedPoems = await NetworkService().search(query);
    setState(() {
      _poems = searchedPoems;
    });
    // Scroll to the last item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastItem();
    });
  }

  void _scrollToLastItem() {
    if (_itemScrollController.isAttached && _poems.isNotEmpty) {
      _itemScrollController.jumpTo(index: _poems.length - 1, alignment: 0.0);
    }
  }

  // Function to handle date picking
  Future<void> _pickDate(BuildContext context) async {
    if (_isSearching) {
      // Exit search mode if currently searching
      setState(() {
        _isSearching = false;
        _searchController.clear();
      });
      // Proceed to open the date picker
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchPoemsForDate(picked);
    } else if (!_isSearching) {
      // If no date was picked and we weren't in search mode, fetch poems for the current selected date
      _fetchPoemsForDate(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = _isSearching
        ? Configs().browsePoemsScreenGet('in_search_mode')
        : '${Configs().browsePoemsScreenGet('date_picker_prompt')} ${DateFormat('yyyy-MM-dd').format(_selectedDate)}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back button
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: GestureDetector(
          onTap: () => _pickDate(context), // Open the date picker when tapped
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 187, 79, 79),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              appBarTitle,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          // Add search field in the AppBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: 200,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: Configs().browsePoemsScreenGet('hint_search'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _poems.isNotEmpty
          ? ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              itemCount: _poems.length,
              itemBuilder: (context, index) {
                return PoemContent(poem: _poems[index], index: index, searchQuery: _searchController.text);
              },
            )
          : Center(
              child: Text(
                Configs().browsePoemsScreenGet(
                    _isSearching ? 'no_search_results' : 'no_poems'),
                style: TextStyle(fontSize: 16),
              ),
            ),
    );
  }
}

// Widget to display the poem content
class PoemContent extends StatelessWidget {
  final Poem poem;
  final int index;
  final String? searchQuery;

  const PoemContent({
    Key? key,
    required this.poem,
    required this.index,
    this.searchQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Color> backgroundColors = [
      Colors.white,
      const Color.fromARGB(255, 219, 255, 209),
      const Color.fromARGB(255, 212, 100, 100),
      const Color.fromARGB(255, 230, 154, 154),
    ];

    Color backgroundColor = backgroundColors[index % backgroundColors.length];

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: _buildHighlightedText(poem.text, searchQuery),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(poem.publishedAt),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _buildHighlightedText(String text, String? query) {
    if (query == null || query.isEmpty) {
      return TextSpan(text: text, style: const TextStyle(fontSize: 18, color: Colors.black));
    } else {
      List<TextSpan> spans = [];
      String lowerCaseText = text.toLowerCase();
      String lowerCaseQuery = query.toLowerCase();

      int start = 0;
      int index = lowerCaseText.indexOf(lowerCaseQuery, start);

      while (index != -1) {
        if (index > start) {
          spans.add(TextSpan(text: text.substring(start, index)));
        }
        spans.add(TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ));
        start = index + query.length;
        index = lowerCaseText.indexOf(lowerCaseQuery, start);
      }

      if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start)));
      }

      return TextSpan(style: const TextStyle(fontSize: 18, color: Colors.black), children: spans);
    }
  }
}
