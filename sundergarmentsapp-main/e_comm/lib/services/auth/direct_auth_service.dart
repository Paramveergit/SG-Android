import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DirectAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final DirectAuthService _instance = DirectAuthService._internal();
  factory DirectAuthService() => _instance;
  DirectAuthService._internal();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('=== Starting Direct Google Sign In Process ===');
      
      // Create a Google provider directly
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Add scopes
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      // Set custom parameters to always prompt for account selection
      googleProvider.setCustomParameters({
        'prompt': 'select_account'
      });

      // Sign in with Firebase directly
      final userCredential = await _auth.signInWithProvider(googleProvider);
      
      debugPrint('Direct Firebase sign in successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e, stackTrace) {
      debugPrint('=== Direct Firebase Sign In Error ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('Sign out successful');
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }
}
