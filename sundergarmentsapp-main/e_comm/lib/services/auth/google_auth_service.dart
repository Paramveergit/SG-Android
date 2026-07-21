// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Single canonical Google Sign-In implementation for this app.
///
/// This used to be one of three separate, independently-maintained Google
/// sign-in code paths that AuthController tried in a cascading fallback
/// (this flow, DirectAuthService.signInWithProvider, and
/// WebOAuthService.signInWithPopup), plus a fourth near-duplicate of this
/// same flow inside GoogleSignInController for the welcome screen.
///
/// That was silently unsafe: signInWithProvider/signInWithPopup can use a
/// different underlying OAuth client than the google_sign_in package, so
/// the SAME Google account could resolve to a DIFFERENT Firebase UID
/// depending on which flow happened to succeed on a given attempt (or
/// which platform build/config a person happened to be using). Since
/// every write in Firestore is keyed by that UID - orders, addresses, the
/// user profile itself - a customer could land on a brand-new empty
/// account after a reinstall while their real order history stayed filed
/// under their original UID, invisible to them, with no error, forever.
///
/// The fix: exactly one Google sign-in flow, used from every entry point
/// in the app (see AuthController and GoogleSignInController, both of
/// which now just delegate here), so the same Google account always
/// produces the same Firebase UID.
class GoogleAuthService {
  final GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: ['email', 'profile']);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  /// Signs in with Google and ensures the Firestore user profile is
  /// created (new accounts) or safely refreshed (existing accounts).
  /// [deviceToken], if provided, is stored for push notifications.
  Future<UserCredential?> signInWithGoogle({String? deviceToken}) async {
    try {
      debugPrint('=== Starting Google Sign In Process ===');

      // Clear any existing session so the account picker always appears.
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint('Google Sign In Response: ${googleUser?.email ?? "No user"}');

      if (googleUser == null) {
        debugPrint('Sign in aborted by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Firebase sign in successful: ${userCredential.user?.email}');

      final user = userCredential.user;
      if (user != null) {
        await _upsertUserProfile(user, deviceToken: deviceToken);
      }

      return userCredential;
    } catch (e, stackTrace) {
      debugPrint('=== Google Sign In Error ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('=========================');
      rethrow;
    }
  }

  /// Creates a fresh profile for a brand-new UID, or - for a UID that
  /// already has a profile - only refreshes the lightweight identity
  /// fields (name/email/photo/device token). Never overwrites saved
  /// address/phone/city or the isAdmin flag on an existing account.
  Future<void> _upsertUserProfile(User user, {String? deviceToken}) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final existingDoc = await docRef.get();
    final existingData = existingDoc.data();

    if (existingDoc.exists) {
      debugPrint('Existing user signed in - preserving saved profile data');
      await docRef.set({
        'username': user.displayName ?? existingData?['username'] ?? 'User',
        'email': user.email ?? existingData?['email'] ?? '',
        'userImg': user.photoURL ?? existingData?['userImg'] ?? '',
        if (deviceToken != null) 'userDeviceToken': deviceToken,
      }, SetOptions(merge: true));
    } else {
      debugPrint('New user - creating profile');
      await docRef.set({
        'uId': user.uid,
        'username': user.displayName ?? 'User',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'userImg': user.photoURL ?? '',
        'userDeviceToken': deviceToken ?? '',
        'country': '',
        'userAddress': '',
        'street': '',
        'isAdmin': false,
        'isActive': true,
        'createdOn': DateTime.now(),
        'city': '',
      });
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
