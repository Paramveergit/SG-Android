import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../services/auth/google_auth_service.dart';
import '../models/user-model.dart';
import '../controllers/get-device-token-controller.dart';

class AuthRepository {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  // Get current user stream
  Stream<User?> get authStateChanges => FirebaseAuth.instance.authStateChanges();

  // Get current user
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Sign in with Google and create/update user document
  Future<UserModel?> signInWithGoogle() async {
    try {
      final userCredential = await _googleAuthService.signInWithGoogle();
      
      if (userCredential?.user == null) {
        throw 'Failed to sign in with Google';
      }

      // Create or update user document
      final user = userCredential!.user!;
      
      // Get device token
      final deviceTokenController = Get.put(GetDeviceTokenController());
      await Future.delayed(const Duration(seconds: 2)); // Wait for token generation
      
      final userModel = UserModel(
        uId: user.uid,
        username: user.displayName ?? 'User',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        userImg: user.photoURL ?? '',
        userDeviceToken: deviceTokenController.deviceToken ?? '',
        createdOn: DateTime.now(),
      );

      await _updateUserData(userModel);
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  // Update user data in Firestore
  Future<void> _updateUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uId).set(
        user.toJson(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw 'Failed to update user data: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleAuthService.signOut();
    } catch (e) {
      throw 'Failed to sign out: $e';
    }
  }
}
