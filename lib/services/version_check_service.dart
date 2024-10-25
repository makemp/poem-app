import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/configs.dart';
import '../main.dart';

class VersionCheckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String storeUrl = '';

  Future<void> checkAppVersion() async {
    if(defaultTargetPlatform != TargetPlatform.iOS || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    String? requiredVersion;
    String? currentVersion;
    

    String versionFirebaseDocumentName = '';
    if(defaultTargetPlatform == TargetPlatform.iOS) {
      versionFirebaseDocumentName = 'version_ios';
    } else {
      versionFirebaseDocumentName = 'version_android';
    }

    try {
      // Fetch the version document from Firestore
      DocumentSnapshot versionDoc = await _firestore.collection('configs').doc(versionFirebaseDocumentName).get();

      if (versionDoc.exists) {
        // Get the current app version
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        currentVersion = packageInfo.version;

        // Get the required version from Firestore
        requiredVersion = versionDoc['value'];
        storeUrl = versionDoc['store_url'];
      }
    } catch (e) {
    }

    // Compare versions and trigger dialog if needed
    if (requiredVersion != null && currentVersion != null && _isVersionOutdated(currentVersion, requiredVersion)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUpdateDialog();
      });
    }
  }

  // Function to compare versions
  bool _isVersionOutdated(String currentVersion, String requiredVersion) {
    List<String> current = currentVersion.split('.');
    List<String> required = requiredVersion.split('.');

    for (int i = 0; i < required.length; i++) {
      int currentNum = int.parse(current[i]);
      int requiredNum = int.parse(required[i]);
      if (currentNum < requiredNum) {
        return true; // App version is lower
      } else if (currentNum > requiredNum) {
        return false; // App version is higher
      }
    }
    return false; // Versions are equal
  }

  // Launch the App Store or Google Play Store
  void _launchAppStore() async {
    // Define the URLs for Play Store and App Store
    final Uri uri = Uri.parse(storeUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'Could not launch $storeUrl';
    }
  }

  // Method to show the update dialog
  void _showUpdateDialog() {
    // Since _showUpdateDialog is scheduled with addPostFrameCallback,
    // make sure it is called when the widget is still mounted.
    final context = navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(Configs().versionCheckServiceGet('title')),
          content: Text(Configs().versionCheckServiceGet('content')),
          actions: <Widget>[
            TextButton(
              child: Text(Configs().versionCheckServiceGet('button')),
              onPressed: () {
                _launchAppStore();
              },
            ),
          ],
        );
      },
    );
  }
}
