import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LinkAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Singleton pattern
  static final LinkAuthService _instance = LinkAuthService._internal();
  factory LinkAuthService() => _instance;
  LinkAuthService._internal();

  // Send sign-in link to email
  Future<void> sendSignInLinkToEmail(String email) async {
    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://sundergarments.page.link/auth',
          handleCodeInApp: true,
          androidPackageName: 'com.sundergarments.ecomm',
          androidInstallApp: true,
          androidMinimumVersion: '12',
        ),
      );
      
      // Save the email locally to use it later
      await GetStorage().write('emailForSignIn', email);
      
      debugPrint('Email link sent successfully');
    } catch (e) {
      debugPrint('Error sending email link: $e');
      rethrow;
    }
  }

  // Sign in with email link
  Future<UserCredential> signInWithEmailLink(String email, String link) async {
    try {
      final userCredential = await _auth.signInWithEmailLink(
        email: email,
        emailLink: link,
      );
      
      // Clear stored email
      await GetStorage().remove('emailForSignIn');
      
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with email link: $e');
      rethrow;
    }
  }
  
  // Check if link is sign-in link
  bool isSignInLink(String link) {
    return _auth.isSignInWithEmailLink(link);
  }
}
