import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:poem_app/firebase_options.dart';

import '../data/configs.dart';

class NetworkService {
  // Create a private constructor
  NetworkService._privateConstructor();

  // Create a single instance of the class
  static final NetworkService _instance = NetworkService._privateConstructor();

  // Factory constructor to return the same instance of the class
  factory NetworkService() {
    return _instance;
  }

  // Initialize Firebase if it hasn't been initialized already
  Future<void> initializeFirebase() async {
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).then((_) {
      Configs().load(); 
    });// Ensure Firebase is initialized
    
  }

  // Read all documents from the "configs" collection
  Future<List<Map<String, dynamic>>> readConfigsCollection() async {
    // Reference to the "configs" collection
    CollectionReference configsCollection = FirebaseFirestore.instance.collection('configs');

     print("CollectionReference: $configsCollection");
    try {
      // Fetch all documents from the collection
      GetOptions options = GetOptions(source: Source.server);
      QuerySnapshot querySnapshot = await configsCollection.get(options);
      print("querySnapshot: $querySnapshot");
      List<QueryDocumentSnapshot<dynamic>> docs = querySnapshot.docs;
      print("Docs: $docs");


      // Convert documents into a List of Map<String, dynamic>
      List<Map<String, dynamic>> configs = querySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      return configs; // Return the list of configs
    } catch (e) {
      print('Error reading configs collection: $e');
      return [];
    }
  }
}
