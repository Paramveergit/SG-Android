import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('=== Starting Google Sign In Process ===');
      
      // Clear any existing sessions
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      // Start sign in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint('Google Sign In Response: ${googleUser?.email ?? "No user"}');

      if (googleUser == null) {
        debugPrint('Sign in aborted by user');
        return null;
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('Got auth tokens - Access Token: ${googleAuth.accessToken?.substring(0, 5)}... ID Token: ${googleAuth.idToken?.substring(0, 5)}...');

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      debugPrint('Created Firebase credential');

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Firebase sign in successful: ${userCredential.user?.email}');
      
      return userCredential;
    } catch (e, stackTrace) {
      debugPrint('=== Google Sign In Error ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('=========================');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      debugPrint('Sign out successful');
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }
}