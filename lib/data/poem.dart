import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poem_app/services/network_service.dart';

class Poem {
  final String id;
  String text;
  DateTime publishedAt;
  DateTime createdAt;
  int heartCount;
  final DocumentSnapshot? documentSnapshot;

  // Constructor
  Poem({
    required this.id,
    required this.text,
    required this.publishedAt,
    required this.createdAt,
    required this.heartCount,
    required this.documentSnapshot, // Initialize in constructor
  });

    factory Poem.fromDocument(QueryDocumentSnapshot doc) {
    return Poem(
      id: doc.id, // Get the document ID
      text: doc['text'],
      publishedAt: (doc['publishedAt'] as Timestamp).toDate(),
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      heartCount: doc['heartCount'] ?? 0,
      documentSnapshot: doc,
    );
  }

  void increaseHeartCount() {
    heartCount = heartCount + 1;
    NetworkService().increaseHeartCount(id);
  }

  void decreaseHeartCount() {
    if (heartCount < 1) {
      return;
    }
    heartCount = heartCount - 1;
    NetworkService().decreaseHeartCount(id);
  }
}