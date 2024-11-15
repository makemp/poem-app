class Comment {
  final String? id;
  final String text;
  final String username; 
  final String createdAt;
  final String updatedAt;


  // Constructor
  Comment({
    this.id,
    required this.text,
    required this.username,
    required this.createdAt,
    required this.updatedAt
  });

  factory Comment.fromJson(Map<String, dynamic> data) {
    return Comment(createdAt: data['createdAt'],id: data['id'], text: data['text'], updatedAt: data['updatedAt'] ?? data['updateAt'], username: data['username']);
  }


  factory Comment.createComment({required String text, required String username}) {
    return Comment(text: text, username: username, createdAt: DateTime.now().toString(), updatedAt: DateTime.now().toString());
  }

  Map<String, dynamic> asMap() {
    return { 'comment': {'text': text, 'username': username}};
  }
}