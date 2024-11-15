import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:poem_app/data/comment.dart';
import 'package:poem_app/main.dart';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import '../data/poem.dart';

class NetworkService {
  static const databaseId = String.fromEnvironment('FIRESTORE_DATABASE_ID', defaultValue: '(default)');


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

  Future<bool> verifyMagicWord() async {
    final url = Uri.parse("$baseUrl/verifyMagicWord");

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String magicWord =  prefs.getString('user_input').toString();

      if (magicWord == "" || magicWord == "null") {
        return false;
      }


      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"magicWord": magicWord}),
      );

      if (response.statusCode == 200) {
        // Parse the response and extract the magic hash
        final responseData = jsonDecode(response.body);
        _postHash =  responseData['magicHash'];
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }


  // Read all documents from the "configs" collection and return them as a structured map
  Future<Map<String, Map<String, dynamic>>> readConfigsCollection() async {
    CollectionReference configsCollection = firestore.collection('configs');

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

  Future<void> addComment(int poemId, Comment comment) async {
    Map<String, dynamic> params = comment.asMap();
    params['poemId'] = poemId;
    params["databaseId"] = databaseId;

    final url = Uri.parse("$baseUrl/addComment");
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(params),
      );
  }

  // Method to publish a new poem to the "poems" collection
  Future<void> publishPoem(String text) async {
    final url = Uri.parse("$baseUrl/publishPoem");
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"magicHash": _postHash, "text": text, "databaseId": databaseId}),
      );
  }

  Future<Poem> fetchPoem(int id) async {
          QuerySnapshot querySnapshot = await firestore
          .collection('poems').where('id', isEqualTo: id).limit(1).get();
          return Poem.fromDocument(querySnapshot.docs.first);
  }

  // Method to fetch all poems published on a specific date
  Future<List<Poem>> fetchPoemsForDate(DateTime date) async {
    try {
      // Format the given date to ensure we're comparing only the date, not time
      DateTime startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      QuerySnapshot querySnapshot = await firestore
          .collection('poems')
          .where('publishedAt', isGreaterThanOrEqualTo: startOfDay)
          .where('publishedAt', isLessThanOrEqualTo: endOfDay)
          .get();

      List<Poem> poems = querySnapshot.docs.map((doc) {
        return Poem.fromDocument(doc);
      }).toList();

      return poems;
    } catch (e) {

      return [];
    }
  }

  Future<Poem> randomPoem(int? seed) async {
   final Random random = Random();

    DocumentSnapshot versionDoc = await firestore.collection('configs').doc('poemCounter').get();
    int randomNumber = random.nextInt(seed ?? versionDoc['count']) + 1;
    
    try{ 
        QuerySnapshot querySnapshot = await firestore
          .collection('poems')
          .where('id', isEqualTo: randomNumber)
          .limit(1)
          .get();

      Poem poem = Poem.fromDocument(querySnapshot.docs.first);
      return poem;
     }catch(e) {
      if (seed == null) {
        return randomPoem(4000);
      }
      rethrow;
    }
  }

    Future<void> increaseHeartCount(int poemId) async {
    final url = Uri.parse("$baseUrl/increaseHeartCount");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"poemId": poemId, "databaseId": databaseId}),
      );

      if (response.statusCode == 200) {
      } else {
      }
    } catch (e) {
    }
  }

  Future<void> decreaseHeartCount(int poemId) async {
    final url = Uri.parse("$baseUrl/decreaseHeartCount");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"poemId": poemId, "databaseId": databaseId}),
      );

      if (response.statusCode == 200) {
      } else {
      }
    } catch (e) {
    }
  }

  Future<Map<String, dynamic>> search(
      String text, {
        int limit = 10,
        DocumentSnapshot? lastDocument,
      }) async {
    try {
      // Build the query
      Query query = firestore
          .collection('poems')
          .where('searchValues', arrayContains: text.toLowerCase())
          .orderBy('publishedAt', descending: true) // Ensure you have an index on 'published_at'
          .limit(limit);

      // Apply the cursor if provided
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Execute the query
      QuerySnapshot querySnapshot = await query.get();

      // Map the results to a list of Poem objects
      List<Poem> poems = querySnapshot.docs.map((doc) {
        return Poem.fromDocument(doc);
      }).toList();

      // Get the last document for the next query
      DocumentSnapshot? newLastDocument = querySnapshot.docs.isNotEmpty
          ? querySnapshot.docs.last
          : null;

      return {
        'poems': poems,
        'lastDocument': newLastDocument,
      };
    } catch (e) {
      return {
        'poems': <Poem>[],
        'lastDocument': null,
      };
    }
  }
}
