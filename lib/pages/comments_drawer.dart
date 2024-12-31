import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:poem_app/data/current_user.dart';
import 'package:poem_app/pages/home_screen.dart';
import 'package:poem_app/services/auth_service.dart';

import '../data/comment.dart';
import '../data/poem.dart';

class CommentsDrawer extends StatefulWidget {
  final Poem? poem;

  const CommentsDrawer({Key? key, this.poem}) : super(key: key);

  @override
  _CommentsDrawerState createState() => _CommentsDrawerState();
}

class _CommentsDrawerState extends State<CommentsDrawer> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> comments = [];

  @override
  Widget build(BuildContext context) {
    print(comments);
    print(widget.poem?.comments.toList());
    if (comments.isEmpty) {
      comments = widget.poem?.comments.toList();
    }
    return Drawer(
      child: SafeArea(
        child: StreamBuilder<User?>(
          stream: AuthService.instance.authStateChanges,
          builder: (context, snapshot) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(),

                // Comments List
                Expanded(
                  child: ListView.builder(
                    // Provide a safe fallback for null
                    itemCount: comments.length ?? 0,
                    itemBuilder: (context, index) {                      // Safely get the comment
                      final comment = comments[index];
                      if (comment == null) return SizedBox();
                      return ListTile(
                        leading: Icon(Icons.person),
                        title: Text(comment.username),
                        subtitle: Text(comment.text),
                      );
                    },
                  ),
                ),

                // Divider before the input area
                Divider(),

                // Comment Input Area
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: _row(snapshot),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Row _row(AsyncSnapshot<User?> snapshot) {
    bool isLoggedIn = snapshot.hasData && snapshot.data != null;
    return isLoggedIn ? _commentRow() : _logInRow();
  }

  Row _commentRow() {
    return Row(
      children: [
        // Expanded TextField
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Dodaj komentarz',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
            ),
          ),
        ),
        SizedBox(width: 8.0),

        // Send Button
        IconButton(
          icon: Icon(Icons.send, color: Colors.blue),
          onPressed: () {
            final newCommentText = _commentController.text.trim();
            if (newCommentText.isNotEmpty) {
              print("Dodaje komentarz");
              setState(() {
                var comment = Comment.createComment(
                    username: CurrentUser().displayName,
                    text: newCommentText,
                  );
                // Add the new comment to the poem
                widget.poem?.addCommentAndReturnSelf(
                  comment
                );
                comments.add(comment);
                // Clear the input field
                _commentController.clear();
              });
            }
          },
        ),
      ],
    );
  }

  Row _logInRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            // If your "different tray" is another screen or widget, navigate there:
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    HomeScreen(openDrawerOnLoad: true), // or your widget
              ),
            );
          },
          child: Text(
            "Zaloguj się, by dodać komentarz",
            style: TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
