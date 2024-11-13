class Comment {
  final String? id;
  final int poemId;
  final String text;
  final String username; 
  final DateTime createdAt;


  // Constructor
  Comment({
    this.id,
    required this.poemId,
    required this.text,
    required this.username,
    required this.createdAt
  });


  factory Comment.createComment({required String text, required String username, required int poemId}) {
    return Comment(poemId: poemId, text: text, username: username, createdAt: DateTime.now());
  }
}