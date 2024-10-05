import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:poem_app/services/network_service.dart';
import '../data/poem.dart'; // Assuming the Poem class is in poem.dart
import 'package:flutter/services.dart' show rootBundle;


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
      heartCount: 0
    );

    _poems.add(newPoem);
    NetworkService().publishPoem(text);
  }

  Future<List<Poem>> display(DateTime publishedAt) async {
    List<Poem> poems = await NetworkService().fetchPoemsForDate(publishedAt);
  
    poems.sort((poemA, poemB) => poemA.createdAt.compareTo(poemB.createdAt));

    return poems;
  }

  

  // Optional: Display all poems for debugging purposes
  void displayAll() {
    if (_poems.isEmpty) {
      print("No poems have been published yet.");
    } else {
      for (Poem poem in _poems) {
        print("Poem published on: ${DateFormat('yyyy-MM-dd').format(poem.publishedAt)}");
        print(poem.text);
        print("-----------");
      }
    }
  }
}
