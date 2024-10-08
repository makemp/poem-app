import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/configs.dart';
import '../main.dart';

class VersionCheckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> checkAppVersion() async {
    if(defaultTargetPlatform != TargetPlatform.iOS || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    String? requiredVersion;
    String? currentVersion;

    try {
      // Fetch the version document from Firestore
      DocumentSnapshot versionDoc = await _firestore.collection('configs').doc('version').get();

      if (versionDoc.exists) {
        // Get the current app version
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        currentVersion = packageInfo.version;

        // Get the required version from Firestore
        requiredVersion = versionDoc['value'];
      }
    } catch (e) {
      print('Error fetching version info: $e');
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
    String url = "https://play.google.com/store/apps/details?id=<YOUR_PACKAGE_NAME>";

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      url = "https://apps.apple.com/app/id<YOUR_APP_ID>";
    }

    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  // Method to show the update dialog
  void _showUpdateDialog() {
    // Since _showUpdateDialog is scheduled with addPostFrameCallback,
    // make sure it is called when the widget is still mounted.
    final context = navigatorKey.currentContext;

    if (context == null) {
      print('Context is not available');
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
