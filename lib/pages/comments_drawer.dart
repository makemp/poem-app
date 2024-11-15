import 'package:flutter/material.dart';

import '../data/comment.dart';
import '../data/poem.dart';

// Define a Poem class or use your existing one

class CommentsDrawer extends StatefulWidget {
  final Poem? poem;

  const CommentsDrawer({Key? key, this.poem}) : super(key: key);

  @override
  _CommentsDrawerState createState() => _CommentsDrawerState();
}


class _CommentsDrawerState extends State<CommentsDrawer> {

  
    @override
    Widget build(BuildContext context) {
  // Controller for the TextField
     TextEditingController _commentController = TextEditingController();

return Drawer(
    child: SafeArea(
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
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
                  itemCount: widget.poem?.comments.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(Icons.person),
                      title: Text(widget.poem?.comments[index]['username']),
                      subtitle: Text(widget.poem?.comments[index]['text']),
                    );
                  },
                ),
              ),
              // Divider before the input area
              Divider(),
              // Comment Input Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Expanded TextField
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
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
                        String newComment = _commentController.text.trim();
                        if (newComment.isNotEmpty) {
                          setState(() {
                            // Add the new comment to the list
                            widget.poem?.addCommentAndReturnSelf(Comment.createComment(username: 'CurrentUser', text: newComment));
                            // Clear the input field
                            _commentController.clear();
                          });
                          // Optionally, you can perform additional actions here, such as sending the comment to a backend
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
    }

}

