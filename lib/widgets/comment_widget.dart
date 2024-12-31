import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/poem.dart';


class CommentWidget extends StatelessWidget {
  final Poem poem;
  final Function openDrawer;

  const CommentWidget({Key? key, required this.poem, required this.openDrawer}) : super(key: key);
  void _openEndDrawer(BuildContext context) {
    openDrawer(poem);
    Scaffold.of(context).openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    int count = this.poem.comments.length;
    return Column(
      children: [
        SizedBox(height: 1.0),
        IconButton(
          icon: Icon(Icons.comment, color: Colors.grey),
          onPressed: () => _openEndDrawer(context)),
        SizedBox(height: 0), // Optional: Add spacing between icon and count
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 16.0,
            color: Colors.grey,
          ),
        ),]);
  }

}