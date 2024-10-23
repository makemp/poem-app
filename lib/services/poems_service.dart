import 'package:intl/intl.dart'; // For date formatting
import 'package:poem_app/services/network_service.dart';
import '../data/poem.dart'; // Assuming the Poem class is in poem.dart


class PoemsService {
  // Internal list to store poems
  //List<Poem> _poems = [];

  final List<Poem> _poems = [];

  // Singleton setup
  static final PoemsService _instance = PoemsService._internal();
  factory PoemsService() => _instance;
  PoemsService._internal();

  // Method to publish a new poem
  void publish(String text) {
    DateTime now = DateTime.now();
    Poem newPoem = Poem(
      id: '',
      text: text,
      publishedAt: now,
      createdAt: now,
      heartCount: 0,
      documentSnapshot: null
    );

    _poems.add(newPoem);
    NetworkService().publishPoem(text);
  }

  Future<List<Poem>> display(DateTime publishedAt) async {
    List<Poem> poems = await NetworkService().fetchPoemsForDate(publishedAt);
  
    poems.sort((poemA, poemB) => poemA.createdAt.compareTo(poemB.createdAt));

    return poems;
  }
}
