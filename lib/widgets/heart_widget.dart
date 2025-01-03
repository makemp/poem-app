import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/poem.dart';

class HeartWidget extends StatefulWidget {
  final Poem poem; // Unique identifier for each poem
  final bool disabled; // This will hold the disabled state

  const HeartWidget({
    required this.poem,
    this.disabled = false, // Default to not disabled
    Key? key,
  }) : super(key: key);

  bool get isDisabled => disabled; // Getter to access disabled state

  @override
  _HeartWidgetState createState() => _HeartWidgetState();
}

class _HeartWidgetState extends State<HeartWidget> {
  bool _isHearted = false; // Tracks whether the user has given a heart locally
  int _heartCount = 0; // The number of hearts fetched from the server
  bool _isDisposed = false; // Flag to prevent setState after dispose

  @override
  void initState() {
    super.initState();
    _loadHeartState(); // Load heart state from SharedPreferences
  }

  @override
  void didUpdateWidget(covariant HeartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the poemId has changed, and if so, update the state accordingly
    if (oldWidget.poem.id != widget.poem.id) {
      _loadHeartState(); // Reload heart state for the new poemId
    }
  }

  @override
  void dispose() {
    _isDisposed = true; // Update the flag
    super.dispose();
  }

  // Load heart state for the given poem from SharedPreferences
  Future<void> _loadHeartState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!_isDisposed) {
      setState(() {
        _isHearted = prefs.getBool('hearted_${widget.poem.id}') ?? false;
        _heartCount = widget.poem.heartCount;
      });
    }
  }

  // Save heart state for the given poem in SharedPreferences
  Future<void> _saveHeartState(bool isHearted) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hearted_${widget.poem.id}', isHearted);
  }

  // Toggle heart state locally and update server heart count
  Future<void> _toggleHeart() async {
    setState(() {
      _isHearted = !_isHearted;
      _heartCount += _isHearted ? 1 : -1; // Update local heart count
      _isHearted ? widget.poem.increaseHeartCount() : widget.poem.decreaseHeartCount();
    });

    // Save the new state locally
    await _saveHeartState(_isHearted);

    // Send heart state update to the server if needed
    // Implement your server update logic here
  }

  @override
  Widget build(BuildContext context) {
    int count = _isHearted && _heartCount < 1 ? 1 : _heartCount;
    count = count < 0 ? 0 : count;
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _isHearted ? Icons.favorite : Icons.favorite_border,
            color: _isHearted ? Colors.red : Colors.grey,
          ),
          onPressed: widget.isDisabled ? null : _toggleHeart,
        ),
        Text('$count', style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
