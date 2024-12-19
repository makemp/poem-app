import 'dart:core';

import 'package:poem_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentUser {
  // Private constructor
  CurrentUser._internal();

  // The singleton instance
  static final CurrentUser _instance = CurrentUser._internal();

  // Factory constructor to return the singleton instance
  factory CurrentUser() {
    return _instance;
  }

  String uid = '';
  String displayName = '';

  CurrentUser build(String uid) {
    CurrentUser inst = CurrentUser();
    inst.uid = uid;
    return inst;
  }

  CurrentUser assignDisplayName(String displayName) {
    CurrentUser inst = CurrentUser();
    inst.displayName = displayName;
    return inst;
  }

  bool isLoggedIn() {
    return uid != "";
  }

  /// Loads the current user from SharedPreferences and verifies against Firestore.
  /// Returns `true` if the user is successfully loaded, `false` otherwise.
  Future<bool> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? storedUid = prefs.getString("current_user_uid");
    String? storedDisplayName = prefs.getString("current_user_displayName");

    if (storedUid == null || storedUid.isEmpty) {
      // No stored UID means no current user
      return false;
    }

    // Verify user existence in Firestore
    final userDoc = await firestore.collection('users').doc(storedUid).get();
    if (userDoc.exists) {
      uid = storedUid;
      displayName = storedDisplayName ?? '';
      return true;
    } else {
      // If the user doesn't exist in Firestore, clear the stored values
      await destroy();
      return false;
    }
  }

  /// Saves the current user to SharedPreferences.
  Future<CurrentUser> save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_uid', uid);
    await prefs.setString('current_user_displayName', displayName);
    return CurrentUser();
  }

  /// Clears the current user from SharedPreferences and resets internal fields.
  Future<void> destroy() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_uid');
    await prefs.remove('current_user_displayName');
    uid = '';
    displayName = '';
  }
}


