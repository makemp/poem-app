import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poem_app/pages/comments_drawer.dart';
import 'package:poem_app/services/version_check_service.dart';
import 'package:poem_app/widgets/comment_widget.dart';
import 'package:poem_app/widgets/radom_poem_widget.dart';
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
  final int _fetchLimit = 10; // Adjusted fetch limit for testing pagination
  DateTime _selectedDate = DateTime.now();
  List<Poem> _poems = [];
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<int> _searchResults = [];
  int _currentSearchIndex = -1;
  DocumentSnapshot? _lastDocument;
  bool _isFetching = false;
  bool _hasMore = true;
  bool _isRandom = false;
  Poem? currentPoem = null;
  int _total_results_length = 0;
  Set<int> _positions = Set();

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  final NetworkService _networkService = NetworkService();

  Timer? _debounce;
  String _currentQuery = '';

  // FocusNode to manage focus on the TextField
  final FocusNode _searchFocusNode = FocusNode();

  // Flag to determine if the search is initial or paginating
  bool _isInitialSearch = true;

  @override
  void initState() {
    super.initState();
    VersionCheckService().checkAppVersion();
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
  _searchFocusNode.dispose();
  super.dispose();
  }

    void _handleRandomPoem(Poem poem) {
      setState(() {
        _poems = [poem];
        _isSearching = false;
        _isRandom = true;
        _isFetching = false;
        _hasMore = false; // No pagination needed for date display
      });
    }

  void _startSearch(String query) {
    setState(() {
      _total_results_length = 0;
      _isRandom = false;
      _isSearching = true;
      _currentQuery = query;
      _positions.clear();
      _poems.clear();
      _lastDocument = null;
      _hasMore = true;
      _searchResults.clear();
      _currentSearchIndex = -1;
      _isInitialSearch = true; // Set flag for initial search
    });
    _searchFocusNode.requestFocus(); // Request focus
    _fetchSearchResults(query);
  }

void _handleScroll() {
  if (_isFetching || !_hasMore || !_isSearching) return;

  final positions = _itemPositionsListener.itemPositions.value;
  if (positions.isEmpty) return;



  _positions.addAll(positions.map((toElement) => toElement.index));  
 

  if (_total_results_length <= _positions.length) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!_isFetching && _hasMore && _isSearching) {
        _fetchMorePoems();
      }
    });
  }
}

  Future<void> _fetchSearchResults(String query) async {
    if (!_hasMore) {
      setState(() {
        _isFetching = false;
      });
    }
    if (_isFetching || !_hasMore) return;

    setState(() {
      _isFetching = true;
    });

    try {
      Map<String, dynamic> results = await _networkService.search(
        query,
        limit: _fetchLimit,
        lastDocument: _lastDocument,
      );

      List<Poem> fetchedPoems = results['poems'] as List<Poem>;
      DocumentSnapshot? fetchedLastDocument = results['lastDocument'] as DocumentSnapshot?;

      if (fetchedPoems.isEmpty) {
        setState(() {
          _hasMore = false;
          _isFetching = false;
        });
        return;
      }

      if (_isInitialSearch) {
        setState(() {
          _poems = fetchedPoems;
          _total_results_length = fetchedPoems.length;
          _lastDocument = fetchedLastDocument;
          _hasMore = fetchedPoems.length == _fetchLimit;
          _isFetching = false;
        });

        _highlightSearchResults(query);
        _isInitialSearch = false;

        // Scroll to the last item (index 0 in reversed list)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToLastItem();
        });

      } else {
        // Capture the current scroll position
        setState(() {
          _poems.addAll(fetchedPoems); // Add new poems at the end
          _total_results_length = _total_results_length + fetchedPoems.length;
          _lastDocument = fetchedLastDocument;
          _hasMore = fetchedPoems.length == _fetchLimit;
          _isFetching = false;
        });

        // Restore the scroll position
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_itemScrollController.isAttached) {
           // _itemScrollController.jumpTo(index: _poems.length -1);
          }
        });
      }

    } catch (e) {
      setState(() {
        _isFetching = false;
      });
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
        _currentSearchIndex = 0; // Start from the bottom (index 0 in reversed list)
      });

      // Scroll to the bottom
      _scrollToIndex(_currentSearchIndex);

    }
  }

  void _exitSearchMode() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchResults.clear();
      _currentSearchIndex = -1;
      _currentQuery = '';
      _poems.clear();
      _lastDocument = null;
      _hasMore = true;
      _isInitialSearch = true; // Reset the flag
    });
    _fetchPoemsForDate(_selectedDate);
    FocusScope.of(context).unfocus();
  }

  void _fetchPoemsForDate(DateTime date) async {
    setState(() {
      _isFetching = true;
    });

    try {
      List<Poem> fetchedPoems = await PoemsService().display(date);

      setState(() {
        _isRandom = false;
        _poems = fetchedPoems;
        _isFetching = false;
        _hasMore = false; // No pagination needed for date display
      });

      // Scroll to the last item (index 0 in reversed list)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToLastItem();
      });

    } catch (e) {
      setState(() {
        _isFetching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load poems for the selected date.')),
      );
    }
  }

  void _fetchMorePoems() {
    if (_isSearching) {
      _fetchSearchResults(_currentQuery);
    } else {
      // Do nothing, as we do not need pagination for date display
    }
  }

void _scrollToLastItem() {
  if (_itemScrollController.isAttached && _poems.isNotEmpty) {
    _itemScrollController.jumpTo(index: _isSearching ? 0 : _poems.length - 1, alignment: _isSearching ? 1.0 : 0);
  }
}

  Future<void> _pickDate(BuildContext context) async {
    if (_isSearching) {
      _exitSearchMode();
    }
    final DateTime? picked = await showDatePicker(
      locale: Locale('pl', 'PL'),
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _poems.clear();
        _lastDocument = null;
        _hasMore = false; // No pagination needed
        _isInitialSearch = true;
      });
      _fetchPoemsForDate(picked);
    }
  }

void _scrollToIndex(int index) {
  if (_itemScrollController.isAttached) {
    _itemScrollController.scrollTo(
      index: index,
      alignment: _isSearching ? 1.0 : 0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}

  void _nextSearchResult() {
    if (_searchResults.isEmpty) return;

    setState(() {
      _currentSearchIndex = (_currentSearchIndex - 1 + _searchResults.length) % _searchResults.length;
    });

    _scrollToIndex(_searchResults[_currentSearchIndex]);
  }

  void _previousSearchResult() {
    if (_searchResults.isEmpty) return;

    setState(() {
      _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
    });

    _scrollToIndex(_searchResults[_currentSearchIndex]);
  }

  // Scroll listener to detect when user reaches near the top
  bool _onScrollNotification(ScrollNotification scrollInfo) {
     _handleScroll();
     return false;
  }

  void openDrawer(Poem poem) {
    setState(() {
      currentPoem = poem;
    });
  }


  @override
  Widget build(BuildContext context) {
    String appBarTitle = _isRandom
        ? Configs().browsePoemsScreenGet('in_random_mode')
        : '${Configs().browsePoemsScreenGet('date_picker_prompt')} ${DateFormat('yyyy-MM-dd').format(_selectedDate)}';

    return Scaffold(
      endDrawer: CommentsDrawer(poem: currentPoem),
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
                      _isInitialSearch = true; // Reset flag on new search
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
                      reverse: _isSearching,
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      itemCount: _poems.length + (_hasMore && _isSearching ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_hasMore && _isSearching && index == _poems.length) {
                          // Show loading indicator at the top during search
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: PoemContent(
                            key: ValueKey(_poems[index].id), // Ensure unique keys
                            poem: _poems[index],
                            index: index,
                            searchQuery: _isSearching ? _currentQuery : null,
                            openDrawer: openDrawer
                          ),
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

            if (_isFetching && _poems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
      floatingActionButton: RandomPoemWidget(
        onPoemPicked: _handleRandomPoem, // Pass the callback here
      )
    );
  }
}

// Widget to display the poem content
class PoemContent extends StatelessWidget {
  final Poem poem;
  final int index;
  final String? searchQuery;
  final Function openDrawer;

  const PoemContent({
    Key? key,
    required this.poem,
    required this.index,
    required this.openDrawer,
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
            Align(alignment: Alignment.centerRight, child: CommentWidget(poem: poem, openDrawer: openDrawer))
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