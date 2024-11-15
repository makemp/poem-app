import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poem_app/services/network_service.dart';
import 'package:poem_app/services/poems_service.dart';

import 'comment.dart';

class Poem {
  final int id;
  String text;
  DateTime publishedAt;
  DateTime createdAt;
  int heartCount;
  final DocumentSnapshot? documentSnapshot;
  final List<Map<String, dynamic>> comments;

  // Constructor
  Poem({
    required this.id,
    required this.text,
    required this.publishedAt,
    required this.createdAt,
    required this.heartCount,
    required this.documentSnapshot, // Initialize in constructor
    required this.comments
  });

    factory Poem.fromDocument(QueryDocumentSnapshot doc) {
      final data = doc.data() as Map<String, dynamic>;
    return Poem(
      id: data['id'], // Get the document ID
      text: data['text'],
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      heartCount: data['heartCount'] ?? 0,
      documentSnapshot: doc,
      comments: data.containsKey('comments') ? doc['comments'] : []
    );
  }

  void increaseHeartCount() {
    heartCount = heartCount + 1;
    NetworkService().increaseHeartCount(id);
  }

  void decreaseHeartCount() {
    heartCount = heartCount - 1;
    NetworkService().decreaseHeartCount(id);
  }

  Future<Poem> refresh() async {
    return await NetworkService().fetchPoem(id);
  }

  Future<Poem> addCommentAndReturnSelf(Comment comment) async {
   PoemsService().addComment(id, comment);
   return await refresh();
  }


}