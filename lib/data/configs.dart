import '../services/network_service.dart';

class Configs {
 Map<String, Map<String, dynamic>> _dict = {};  // Use a Map<String, String> to store configurations

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
    Map<String, Map<String, dynamic>> configs = await NetworkService().readConfigsCollection();


   
    // Populate the _dict map with the configuration values
    _dict = configs;
  }

  // Get a specific configuration by key
  Map<String, dynamic>? get(String key) {
    return _dict[key];
  }

  String firstScreenGet(String key) {
    return get('first_screen')?[key].toString() ?? 'Nana';
  }

  String unlockScreenGet(String key) {
    return get('unlock_screen')![key].toString();
  }

  String addPoemScreenGet(String key) {
    return get('add_poem_screen')![key].toString();
  }

  String browsePoemsScreenGet(String key) {
    return get('browse_poem_screen')![key].toString();
  }

  String magicWord() {
    return get('secrets')!['magic_word'];
  }

  String versionCheckServiceGet(String key) {
    return get('version_check_service')![key].toString();
  }
}
