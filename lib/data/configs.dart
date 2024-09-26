import '../services/network_service.dart';

class Configs {
  Map<String, dynamic> _dict = {};  // Use a Map<String, String> to store configurations

  // Private constructor for singleton pattern
  Configs._privateConstructor();

  // Singleton instance
  static final Configs _instance = Configs._privateConstructor();

  // Factory constructor to return the same instance of the class
  factory Configs() {
    return _instance;
  }

  // Load the configurations from Firestore
  Future<void> load() async {
    // Use NetworkService to read the configs from the Firestore database
    List<Map<String, dynamic>> configs = await NetworkService().readConfigsCollection();

    print('Configs preloaded: $configs');

    // Populate the _dict map with the configuration values
    _dict = {for (var config in configs) ...config};

    print('Configs loaded: $_dict');  // Debug print
  }

  // Get a specific configuration by key
  Map<String, String> get(String key) {
    return _dict[key] ?? {};
  }

  String firstScreenGet(String key) {
    return get('first_screen')[key].toString();
  }
}
