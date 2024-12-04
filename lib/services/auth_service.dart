// services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Singleton pattern
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the authentication details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google [UserCredential]
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // If the user is new, create a new document in Firestore
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserInFirestore(userCredential.user);
      } else {
        // Update last login timestamp
        await updateLastLogin(userCredential.user);
      }

      return userCredential;
    } catch (e) {
      print('Error during Google sign-in: $e');
      rethrow;
    }
  }

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      // Request credentials from Apple
      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an OAuthCredential for Firebase
      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple [UserCredential]
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // If the user is new, create a new document in Firestore
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserInFirestore(userCredential.user);
      } else {
        // Update last login timestamp
        await updateLastLogin(userCredential.user);
      }

      return userCredential;
    } catch (e) {
      print('Error during Apple sign-in: $e');
      rethrow;
    }
  }

  /// Sign out from all authentication providers
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Apple Sign-In does not require explicit sign-out
    } catch (e) {
      print('Error during sign-out: $e');
      rethrow;
    }
  }

  /// Create a new user document in Firestore
  Future<void> _createUserInFirestore(User? user) async {
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);

    final userData = {
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'providers': user.providerData.map((provider) => provider.providerId).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };

    await userDoc.set(userData, SetOptions(merge: true));
  }

  /// Update the last login timestamp for an existing user
  Future<void> updateLastLogin(User? user) async {
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);

    await userDoc.update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  /// Get the currently signed-in user
  User? get currentUser => _auth.currentUser;
}
