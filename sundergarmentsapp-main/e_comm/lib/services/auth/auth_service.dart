import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  error
}

class AuthError {
  final String code;
  final String message;
  
  AuthError(this.code, this.message);
  
  @override
  String toString() => message;
}

class AuthService extends GetxController {
  static AuthService get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  
  final Rx<AuthStatus> _status = AuthStatus.initial.obs;
  final Rx<User?> _user = Rx<User?>(null);
  final Rx<AuthError?> _error = Rx<AuthError?>(null);
  
  // Getters
  AuthStatus get status => _status.value;
  User? get user => _user.value;
  AuthError? get error => _error.value;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    _auth.authStateChanges().listen(_handleAuthStateChange);
  }
  
  void _handleAuthStateChange(User? user) {
    _user.value = user;
    _status.value = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }
  
  void _handleError(dynamic error) {
    String code = 'unknown';
    String message = 'An unknown error occurred';
    
    if (error is FirebaseAuthException) {
      code = error.code;
      message = _getFirebaseErrorMessage(error.code);
    } else if (error is PlatformException) {
      code = error.code;
      if (error.code == 'sign_in_failed') {
        if (error.message?.contains('ApiException: 10:') ?? false) {
          code = 'oauth_config';
          message = 'Google Sign-In configuration error. Please try again later.';
        } else {
          message = 'Sign in failed. Please try again.';
        }
      } else {
        message = error.message ?? 'Platform error occurred';
      }
    }
    
    _error.value = AuthError(code, message);
    _status.value = AuthStatus.error;
  }
  
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Invalid password.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
  
  Future<bool> signInWithGoogle() async {
    try {
      _status.value = AuthStatus.initial;
      _error.value = null;
      
      // Check if already signed in to Google
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      // Start Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _handleError(PlatformException(
          code: 'sign_in_cancelled',
          message: 'Sign in was cancelled by the user'
        ));
        return false;
      }
      
      // Get auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        return true;
      } else {
        _handleError(AuthError('no_user', 'Failed to get user information'));
        return false;
      }
      
    } catch (error) {
      _handleError(error);
      return false;
    }
  }
  
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (error) {
      _handleError(error);
    }
  }
  
  void clearError() {
    _error.value = null;
  }
}
