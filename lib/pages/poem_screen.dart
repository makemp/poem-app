import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poem_app/widgets/heart_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
  List<int> _searchResults = [];
  int _currentSearchIndex = -1;

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
          _searchResults.clear();
          _currentSearchIndex = -1;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchPoemsForDate(DateTime date) async {
    List<Poem> fetchedPoems = await PoemsService().display(date);
    setState(() {
      _poems = fetchedPoems;
      _isSearching = false;
      _searchResults.clear();
      _currentSearchIndex = -1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastItem();
    });
  }

  void _searchPoems(String query) async {
    List<Poem> searchedPoems = await NetworkService().search(query);
    setState(() {
      _poems = searchedPoems;
      _searchResults.clear();
      _currentSearchIndex = -1;
    });

    for (int i = 0; i < _poems.length; i++) {
      if (_poems[i].text.toLowerCase().contains(query.toLowerCase())) {
        _searchResults.add(i);
      }
    }

    if (_searchResults.isNotEmpty) {
      _currentSearchIndex = 0;
      _scrollToIndex(_searchResults[_currentSearchIndex]);
    }
  }

  void _scrollToLastItem() {
    if (_itemScrollController.isAttached && _poems.isNotEmpty) {
      _itemScrollController.jumpTo(index: _poems.length - 1, alignment: 0.0);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    if (_isSearching) {
      setState(() {
        _isSearching = false;
        _searchController.clear();
      });
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
    }
  }

  void _scrollToIndex(int index) {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(index: index, duration: Duration(milliseconds: 500));
    }
  }

  void _nextSearchResult() {
    if (_searchResults.isNotEmpty) {
      setState(() {
        _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
      });
      _scrollToIndex(_searchResults[_currentSearchIndex]);
    }
  }

  void _previousSearchResult() {
    if (_searchResults.isNotEmpty) {
      setState(() {
        _currentSearchIndex = (_currentSearchIndex - 1 + _searchResults.length) % _searchResults.length;
      });
      _scrollToIndex(_searchResults[_currentSearchIndex]);
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: Align(
                alignment: _isSearching ? Alignment.centerLeft : Alignment.center,
                child: GestureDetector(
                  onTap: () => _pickDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 187, 79, 79),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appBarTitle,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            if (_isSearching) ...[
              const SizedBox(width: 16),
              SizedBox(
                width: 200, // Adjust width as needed
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    suffixIcon: _searchResults.isNotEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_upward),
                                onPressed: _previousSearchResult,
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_downward),
                                onPressed: _nextSearchResult,
                              ),
                            ],
                          )
                        : null,
                    hintText: Configs().browsePoemsScreenGet('hint_search'),
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
            ],
          ],
        ),
        centerTitle: !_isSearching, // Keeps title centered if search bar is not active
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching; // Toggle visibility of the search field
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _poems.isNotEmpty
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
          ),
        ],
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

    return Padding(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Expanded widget to take most of the space for the text content
            Expanded(
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
            // Add some space between the poem text and heart icon
            const SizedBox(width: 16),
            // HeartWidget positioned to the right of the text
            Align(
              alignment: Alignment.centerRight,
              child: HeartWidget(poem: poem),
            ),
          ],
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

