import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/poem.dart';


class CommentWidget extends StatelessWidget {
  final int poemId;
  final Function openDrawer;

  const CommentWidget({Key? key, required this.poemId, required this.openDrawer}) : super(key: key);
  void _openEndDrawer(BuildContext context) {
    openDrawer(poemId);
    Scaffold.of(context).openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(Icons.comment, color: Colors.grey),
          onPressed: () => _openEndDrawer(context))]);
  }

}