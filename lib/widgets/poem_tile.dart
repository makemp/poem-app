import 'package:flutter/material.dart';
import '../data/poem.dart';
import 'heart_widget.dart'; // Assuming you have a Poem class

class PoemTile extends StatefulWidget {
  final List<Poem> poems;
  final int initialIndex;

  const PoemTile({super.key, required this.poems, this.initialIndex = 0});

  @override
  _PoemTileState createState() => _PoemTileState();
}

class _PoemTileState extends State<PoemTile> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  // Navigate to the previous poem
  void _previousPoem() {
    setState(() {
      currentIndex = (currentIndex - 1 + widget.poems.length) % widget.poems.length;
    });
  }

  // Navigate to the next poem
  void _nextPoem() {
    setState(() {
      currentIndex = (currentIndex + 1) % widget.poems.length;
    });
  }

  void _firstPoem() {
    setState(() {
      currentIndex = 0;
    });
  }

  // Build the poem tile
  @override
  Widget build(BuildContext context) {
    Poem currentPoem;
    try {
      currentPoem = widget.poems[currentIndex];
    } on RangeError {
      currentIndex = 0;
      currentPoem = widget.poems[currentIndex];
    
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous Poem Arrow
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousPoem,
                ),
                // Poem Text and Info
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Poem Text
                              Text(
                                currentPoem.text,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: 8),
                              // Published Date
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                 HeartWidget(poem: currentPoem),
                // Next Poem Arrow
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _nextPoem,
                ),
              ],
            ),
          ),
       ],
      ),
    );
  }
}
