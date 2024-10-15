import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:poem_app/firebase_options.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import '../data/configs.dart';
import '../data/poem.dart';

class NetworkService {
  // Private constructor for singleton pattern
  NetworkService._privateConstructor();
    final String baseUrl = "https://europe-west3-poem-app-2c3c7.cloudfunctions.net";
    String _postHash = "";
  // Create a single instance of the class
  static final NetworkService _instance = NetworkService._privateConstructor();

  // Factory constructor to return the same instance of the class
  factory NetworkService() {
    return _instance;
  }

  // Initialize Firebase if it hasn't been initialized already
  Future<void> initializeFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          name: 'poem-app-project',
          options: DefaultFirebaseOptions.currentPlatform);
      await Configs().load();
    }
  }

  Future<bool> verifyMagicWord() async {
    final url = Uri.parse("$baseUrl/verifyMagicWord");

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String magicWord =  prefs.getString('user_input').toString();

      if (magicWord == "" || magicWord == "null") {
        return false;
      }

      print("Sending magic word: $magicWord");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"magicWord": magicWord}),
      );

      if (response.statusCode == 200) {
        // Parse the response and extract the magic hash
        final responseData = jsonDecode(response.body);
        _postHash =  responseData['magicHash'];
        print("PostHash $_postHash");
        return true;
      } else {
        print("Failed to verify magic word: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error verifying magic word: $e");
      return false;
    }
  }


  // Read all documents from the "configs" collection and return them as a structured map
  Future<Map<String, Map<String, dynamic>>> readConfigsCollection() async {
    CollectionReference configsCollection = FirebaseFirestore.instance.collection('configs');

    try {
      GetOptions options = const GetOptions(source: Source.server);
      QuerySnapshot querySnapshot = await configsCollection.get(options);
      List<QueryDocumentSnapshot<dynamic>> docs = querySnapshot.docs;

      Map<String, Map<String, dynamic>> structuredConfigs = {};

      for (var doc in docs) {
        structuredConfigs[doc.id] = doc.data() as Map<String, dynamic>;
      }

      return structuredConfigs;
    } catch (e) {
      return {};
    }
  }

  // Method to publish a new poem to the "poems" collection
  Future<void> publishPoem(String text) async {
    final url = Uri.parse("$baseUrl/publishPoem");
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"magicHash": _postHash, "text": text}),
      );
  }

  // Method to fetch all poems published on a specific date
  Future<List<Poem>> fetchPoemsForDate(DateTime date) async {
    try {
      // Format the given date to ensure we're comparing only the date, not time
      DateTime startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('poems')
          .where('publishedAt', isGreaterThanOrEqualTo: startOfDay)
          .where('publishedAt', isLessThanOrEqualTo: endOfDay)
          .get();

      List<Poem> poems = querySnapshot.docs.map((doc) {
        return Poem.fromDocument(doc);
      }).toList();

      return poems;
    } catch (e) {
      print('Error fetching poems: $e');
      return [];
    }
  }

    Future<void> increaseHeartCount(String poemId) async {
    final url = Uri.parse("$baseUrl/increaseHeartCount");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"poemId": poemId}),
      );

      if (response.statusCode == 200) {
        print("Heart count successfully incremented.");
      } else {
        print("Failed to increment heart count: ${response.body}");
      }
    } catch (e) {
      print("Error incrementing heart count: $e");
    }
  }

  Future<void> decreaseHeartCount(String poemId) async {
    final url = Uri.parse("$baseUrl/decreaseHeartCount");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"poemId": poemId}),
      );

      if (response.statusCode == 200) {
        print("Heart count successfully decremented.");
      } else {
        print("Failed to decrement heart count: ${response.body}");
      }
    } catch (e) {
      print("Error decrementing heart count: $e");
    }
  }

Future<List<Poem>> search(String text) async {
  try {
    // Query Firestore for poems where the 'text' field contains the search text.
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('poems')
        .where('searchValues', arrayContains: text.toLowerCase())// Ensures substring matching
        .get();

    // Map the results to a list of Poem objects.
    List<Poem> poems = querySnapshot.docs.map((doc) {
      return Poem.fromDocument(doc);
    }).toList();

    return poems;
  } catch (e) {
    print('Error searching for poems: $e');
    return [];
  }
}
}
