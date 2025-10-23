import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../models/user-model.dart';
import '../services/auth/google_auth_service.dart';
import '../services/auth/web_oauth_service.dart';
import '../services/auth/direct_auth_service.dart';
import '../services/auth/email_auth_service.dart';
import '../screens/user-panel/new-main-screen.dart';
import '../screens/auth-ui/home-router.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final WebOAuthService _webOAuthService = WebOAuthService();
  final DirectAuthService _directAuthService = DirectAuthService();
  final EmailAuthService _emailAuthService = EmailAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _isLoading = false.obs;
  final _error = Rxn<String>();
  
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;

  Future<void> signInWithGoogle() async {
    if (_isLoading.value) return;
    
    try {
      _isLoading.value = true;
      _error.value = null;
      EasyLoading.show(status: 'Signing in...');

      // Try direct Firebase auth first
      UserCredential? userCredential;
      try {
        userCredential = await _directAuthService.signInWithGoogle();
      } catch (e) {
        debugPrint('Direct auth failed, trying web OAuth flow: $e');
        try {
          userCredential = await _webOAuthService.signInWithGoogle(Get.context!);
        } catch (e) {
          debugPrint('Web OAuth failed, trying native flow: $e');
          // Fall back to native flow if all else fails
          userCredential = await _googleAuthService.signInWithGoogle();
        }
      }
      
      if (userCredential?.user == null) {
        debugPrint('Sign in cancelled or failed');
        EasyLoading.showError('Sign in cancelled');
        return;
      }

      final user = userCredential!.user!;
      debugPrint('Creating user model for: ${user.email}');

      // Create or update user document
      final userModel = UserModel(
        uId: user.uid,
        username: user.displayName ?? 'User',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        userImg: user.photoURL ?? '',
        createdOn: DateTime.now(),
      );

      await _updateUserData(userModel);
      
      EasyLoading.showSuccess('Welcome ${userModel.username}!');
      // Centralize routing to maintain backward compatibility
      Get.offAll(() => HomeRouter());
      
    } catch (e, stackTrace) {
      debugPrint('=== Auth Error ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('================');
      
      String errorMessage = 'Sign in failed';
      
      if (e is FirebaseAuthException) {
        errorMessage = _getFirebaseErrorMessage(e.code);
      } else if (e is PlatformException) {
        errorMessage = e.message ?? 'Platform error occurred';
      }
      
      _error.value = errorMessage;
      EasyLoading.showError(errorMessage);
      
    } finally {
      _isLoading.value = false;
      if (EasyLoading.isShow) {
        EasyLoading.dismiss();
      }
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Account exists with different credentials';
      case 'invalid-credential':
        return 'Invalid credentials';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled';
      case 'user-disabled':
        return 'User account has been disabled';
      case 'user-not-found':
        return 'User not found';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      default:
        return 'Authentication error: $code';
    }
  }

  Future<void> _updateUserData(UserModel userModel) async {
    try {
      debugPrint('Updating user data in Firestore');
      await _firestore
          .collection('users')
          .doc(userModel.uId)
          .set(userModel.toJson(), SetOptions(merge: true));
      debugPrint('User data updated successfully');
    } catch (e) {
      debugPrint('Error updating user data: $e');
      throw 'Failed to update user data';
    }
  }
  
  // Create user in Firestore from email auth
  Future<void> createUserInFirestore(User user) async {
    try {
      final userModel = UserModel(
        uId: user.uid,
        username: user.displayName ?? user.email?.split('@')[0] ?? 'User',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        userImg: user.photoURL ?? '',
        createdOn: DateTime.now(),
      );
      
      await _updateUserData(userModel);
    } catch (e) {
      debugPrint('Error creating user in Firestore: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      EasyLoading.show(status: 'Signing out...');
      await _googleAuthService.signOut();
      EasyLoading.showSuccess('Signed out successfully');
    } catch (e) {
      debugPrint('Sign out error: $e');
      EasyLoading.showError('Failed to sign out');
    } finally {
      if (EasyLoading.isShow) {
        EasyLoading.dismiss();
      }
    }
  }
}