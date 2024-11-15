class Comment {
  final String? id;
  final String text;
  final String username; 
  final DateTime createdAt;
  final DateTime updatedAt;


  // Constructor
  Comment({
    this.id,
    required this.text,
    required this.username,
    required this.createdAt,
    required this.updatedAt
  });


  factory Comment.createComment({required String text, required String username}) {
    return Comment(text: text, username: username, createdAt: DateTime.now(), updatedAt: DateTime.now());
  }

  Map<String, dynamic> asMap() {
    return { 'comment': {'text': text, 'username': username}};
  }
}