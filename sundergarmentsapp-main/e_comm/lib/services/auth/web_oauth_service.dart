import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WebOAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final WebOAuthService _instance = WebOAuthService._internal();
  factory WebOAuthService() => _instance;
  WebOAuthService._internal();

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      debugPrint('=== Starting Web OAuth Google Sign In Process ===');
      
      // Create a new provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Add scopes
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      // Set custom parameters
      googleProvider.setCustomParameters({
        'login_hint': 'user@example.com',
        'prompt': 'select_account'
      });

      // Sign in with popup/redirect
      UserCredential userCredential;
      
      // On mobile, use signInWithPopup
      userCredential = await _auth.signInWithPopup(googleProvider);
      
      debugPrint('Web OAuth sign in successful: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('=== Firebase Auth Exception ===');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('=== Web OAuth Sign In Error ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('Sign out successful');
  }
}
