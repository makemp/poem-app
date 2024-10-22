import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../data/configs.dart';
import '../data/poem.dart';
import '../services/network_service.dart';
import '../services/poems_service.dart';
import '../widgets/heart_widget.dart';
import 'dart:async';

class PoemScreen extends StatefulWidget {
  const PoemScreen({Key? key}) : super(key: key);

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
  DocumentSnapshot? _lastDocument;
  bool _isFetching = false;
  bool _hasMore = true;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  final NetworkService _networkService = NetworkService();

  // Stack to maintain cursor history for "Previous" functionality
  List<DocumentSnapshot> _cursorStack = [];

  Timer? _debounce;
  String _currentQuery = '';

  // FocusNode to manage focus on the TextField
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchPoemsForDate(_selectedDate);

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        String query = _searchController.text.trim();
        if (query.length >= 4) {
          if (!_isSearching || query != _currentQuery) {
            _startSearch(query);
          }
        }
        // Do not modify _isSearching here
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose(); // Dispose the FocusNode
    super.dispose();
  }

  void _startSearch(String query) {
    setState(() {
      _isSearching = true;
      print('Search started: _isSearching set to true');
      _currentQuery = query;
      _poems.clear();
      _lastDocument = null;
      _hasMore = true;
      _searchResults.clear();
      _currentSearchIndex = -1;
      _cursorStack.clear();
    });
    _searchFocusNode.requestFocus(); // Request focus
    _fetchSearchResults(query);
  }

  Future<void> _fetchSearchResults(String query) async {
    if (_isFetching || !_hasMore) return;

    setState(() {
      _isFetching = true;
      print('Fetching search results...');
    });

    try {
      Map<String, dynamic> results = await _networkService.search(
        query,
        limit: 10,
        lastDocument: _lastDocument,
      );

      List<Poem> fetchedPoems = results['poems'] as List<Poem>;
      DocumentSnapshot? fetchedLastDocument = results['lastDocument'] as DocumentSnapshot?;

      setState(() {
        _poems.addAll(fetchedPoems);
        if (_lastDocument != null) {
          _cursorStack.add(_lastDocument!);
        }
        _lastDocument = fetchedLastDocument;
        _hasMore = fetchedPoems.length == 10;
        _isFetching = false;
        print('Fetched ${fetchedPoems.length} poems. Has more: $_hasMore');
      });

      _highlightSearchResults(query);
    } catch (e) {
      setState(() {
        _isFetching = false;
      });
      print('Error during search: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load poems. Please try again.')),
      );
    }
  }

  void _highlightSearchResults(String query) {
    _searchResults.clear();
    String lowerCaseQuery = query.toLowerCase();

    for (int i = 0; i < _poems.length; i++) {
      if (_poems[i].text.toLowerCase().contains(lowerCaseQuery)) {
        _searchResults.add(i);
      }
    }

    if (_searchResults.isNotEmpty) {
      setState(() {
        _currentSearchIndex = 0;
      });
      _scrollToIndex(_searchResults[_currentSearchIndex]);
      print('Found ${_searchResults.length} search results.');
    }
  }

  void _exitSearchMode() {
    setState(() {
      _isSearching = false;
      print('Search exited: _isSearching set to false');
      _searchController.clear();
      _searchResults.clear();
      _currentSearchIndex = -1;
      _currentQuery = '';
      _poems.clear();
      _lastDocument = null;
      _hasMore = true;
      _cursorStack.clear();
    });
    _fetchPoemsForDate(_selectedDate);
    FocusScope.of(context).unfocus();
  }

  void _fetchPoemsForDate(DateTime date) async {
    // Implement your PoemService().display(date) to fetch poems by date
    try {
      List<Poem> fetchedPoems = await PoemsService().display(date);
      setState(() {
        _poems = fetchedPoems;
        _isSearching = false;
        _searchResults.clear();
        _currentSearchIndex = -1;
        _hasMore = fetchedPoems.length >= 10;
        _lastDocument = fetchedPoems.isNotEmpty
            ? fetchedPoems.last.documentSnapshot
            : null;
        print('Fetched ${fetchedPoems.length} poems for date. Has more: $_hasMore');
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToLastItem();
      });
    } catch (e) {
      print('Error fetching poems for date: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load poems for the selected date.')),
      );
    }
  }

  void _scrollToLastItem() {
    if (_itemScrollController.isAttached && _poems.isNotEmpty) {
      _itemScrollController.jumpTo(index: _poems.length - 1, alignment: 0.0);
      print('Scrolled to last item.');
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    if (_isSearching) {
      _exitSearchMode();
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
        print('Date selected: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
      });
      _fetchPoemsForDate(picked);
    }
  }

  void _scrollToIndex(int index) {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      print('Scrolled to index: $index');
    }
  }

  void _nextSearchResult() {
    if (_searchResults.isEmpty) return;

    setState(() {
      _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
      print('Navigated to next search result: $_currentSearchIndex');
    });

    _scrollToIndex(_searchResults[_currentSearchIndex]);
  }

  void _previousSearchResult() {
    if (_searchResults.isEmpty) return;

    setState(() {
      _currentSearchIndex =
          (_currentSearchIndex - 1 + _searchResults.length) % _searchResults.length;
      print('Navigated to previous search result: $_currentSearchIndex');
    });

    _scrollToIndex(_searchResults[_currentSearchIndex]);
  }

  // Scroll listener to detect when user reaches near the bottom
  bool _onScrollNotification(ScrollNotification scrollInfo) {
    if (!_isFetching &&
        _hasMore &&
        scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
      print('Near bottom of the list. Fetching more poems...');
      _fetchSearchResults(_currentQuery);
    }
    return false;
  }

  // Function to handle "Previous Page" fetch
  void _previousPage() async {
    if (_cursorStack.isEmpty) return;

    DocumentSnapshot previousCursor = _cursorStack.removeLast();
    print('Fetching previous page with cursor: ${previousCursor.id}');

    setState(() {
      _lastDocument = previousCursor;
      _poems.clear();
      _hasMore = true;
      _isFetching = false;
    });

    await _fetchSearchResults(_currentQuery);
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
        title: _isSearching
            ? TextField(
          controller: _searchController,
          focusNode: _searchFocusNode, // Assign the FocusNode
          autofocus: false, // Managed focus manually
          decoration: InputDecoration(
            hintText: Configs().browsePoemsScreenGet('hint_search'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          ),
        )
            : GestureDetector(
          onTap: () => _pickDate(context),
          child: Container(
            padding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
        centerTitle: !_isSearching, // Keeps title centered if search bar is not active
        actions: [
          _isSearching
              ? IconButton(
            icon: Icon(Icons.close),
            onPressed: _exitSearchMode,
          )
              : IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = true;
                print('Search button pressed: _isSearching set to true');
              });
            },
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: Column(
          children: [
            if (_isFetching && _poems.isNotEmpty)
              LinearProgressIndicator(),
            Expanded(
              child: _poems.isNotEmpty
                  ? ScrollablePositionedList.builder(
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
                itemCount: _poems.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _poems.length) {
                    // Show loading indicator at the bottom
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return PoemContent(
                    poem: _poems[index],
                    index: index,
                    searchQuery: _isSearching ? _currentQuery : null,
                  );
                },
              )
                  : _isFetching
                  ? Center(child: CircularProgressIndicator())
                  : Center(
                child: Text(
                  Configs().browsePoemsScreenGet(
                      _isSearching ? 'no_search_results' : 'no_poems'),
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            if (_isFetching && _isSearching)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
          ],
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
      const Color.fromARGB(255, 171, 218, 243),
      const Color.fromARGB(255, 215, 150, 230),
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
      return TextSpan(
          text: text, style: const TextStyle(fontSize: 18, color: Colors.black));
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

      return TextSpan(
          style:
          const TextStyle(fontSize: 18, color: Colors.black),
          children: spans);
    }
  }
}
