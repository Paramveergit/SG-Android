// ignore_for_file: file_names, unused_local_variable, unused_field, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_comm/controllers/get-device-token-controller.dart';
import 'package:e_comm/models/user-model.dart';
import 'package:e_comm/screens/user-panel/main-screen.dart';
import 'package:e_comm/screens/auth-ui/home-router.dart';
import 'package:e_comm/utils/app-constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInController extends GetxController {
  // Updated configuration - remove hardcoded clientId for better cross-platform support
  final GoogleSignIn googleSignIn = GoogleSignIn(
    // Remove clientId to use default from google-services.json and Info.plist
    scopes: ['email', 'profile'],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    // Verify Google Sign-In configuration on initialization
    _verifyGoogleSignInConfig();
  }

  void _verifyGoogleSignInConfig() {
    print("=== Google Sign-In Configuration Verification ===");
    print("Firebase Auth instance: ${_auth.app.name}");
    print("Google Sign-In instance created successfully");
    print("================================================");
  }

  Future<void> signInWithGoogle() async {
    try {
      print("=== Starting Google Sign-In Process ===");
      EasyLoading.show(status: "Signing in...");
      
      // Initialize device token controller if not already initialized
      GetDeviceTokenController getDeviceTokenController;
      try {
        getDeviceTokenController = Get.find<GetDeviceTokenController>();
        print("Device token controller found: ${getDeviceTokenController.deviceToken}");
      } catch (e) {
        print("Device token controller not found, initializing...");
        getDeviceTokenController = Get.put(GetDeviceTokenController());
        // Wait a bit for the token to be generated
        await Future.delayed(const Duration(seconds: 2));
      }

      // Sign out any existing Google account first (clean slate)
      await googleSignIn.signOut();
      
      // Attempt Google Sign In
      print("Attempting Google Sign In...");
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        print("Google Sign-In successful for: ${googleSignInAccount.email}");
        EasyLoading.show(status: "Please wait..");
        
        // Get authentication details
        print("Getting authentication details...");
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        print("Access token obtained: ${googleSignInAuthentication.accessToken != null}");
        print("ID token obtained: ${googleSignInAuthentication.idToken != null}");

        // Create Firebase credential
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        // Sign in to Firebase
        print("Signing in to Firebase...");
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        final User? user = userCredential.user;
        print("Firebase User obtained: ${user?.email}");

        if (user != null) {
          // Create user model with proper null safety
          UserModel userModel = UserModel(
            uId: user.uid,
            username: user.displayName ?? 'User',
            email: user.email ?? '',
            phone: user.phoneNumber ?? '',
            userImg: user.photoURL ?? '',
            userDeviceToken: getDeviceTokenController.deviceToken.toString(),
            country: '',
            userAddress: '',
            street: '',
            isAdmin: false,
            isActive: true,
            createdOn: DateTime.now(),
            city: '',
          );

          // Save user data to Firestore
          print("Saving user data to Firestore...");
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(userModel.toJson());
          print("User data saved to Firestore for UID: ${user.uid}");
          
          EasyLoading.dismiss();
          // Route through centralized home router for consistency
          Get.offAll(() => HomeRouter());
        } else {
          EasyLoading.dismiss();
          Get.snackbar(
            "Sign In Error",
            "Firebase user is null after sign in.",
            snackPosition: SnackPosition.BOTTOM,
          );
          print("Firebase user is null after sign in.");
        }
      } else {
        EasyLoading.dismiss();
        Get.snackbar(
          "Sign In Canceled",
          "Google sign in was canceled or no account was selected.",
          snackPosition: SnackPosition.BOTTOM,
        );
        print("Google sign in was canceled or no account was selected.");
      }
    } catch (e) {
      EasyLoading.dismiss();
      
      print("=== Google Sign-In Error Details ===");
      print("Error type: ${e.runtimeType}");
      print("Error message: $e");
      print("Error toString: ${e.toString()}");
      print("================================");
      
      // Enhanced error handling with specific error messages
      String errorMessage = "Sign-in failed";
      
      if (e.toString().contains('ApiException: 10') || e.toString().contains('DEVELOPER_ERROR')) {
        errorMessage = "OAuth configuration error. Check SHA-1 fingerprint in Firebase Console.";
        print("This appears to be an OAuth configuration issue (Error 10)");
        print("Common solutions:");
        print("1. Verify SHA-1 certificate fingerprint in Firebase Console");
        print("2. Package name matches exactly: com.example.e_comm");
        print("3. Google Sign-In is enabled in Firebase Console");
        print("4. google-services.json is up to date");
        print("5. Clean and rebuild the project");
      } else if (e.toString().contains('ApiException: 12') || e.toString().contains('SIGN_IN_REQUIRED')) {
        errorMessage = "Google Play Services not available or outdated.";
        print("Google Play Services issue - user needs to update Google Play Services");
      } else if (e.toString().contains('ApiException: 7') || e.toString().contains('NETWORK_ERROR')) {
        errorMessage = "Network error. Please check your internet connection.";
      } else if (e.toString().contains('cancelled') || e.toString().contains('SIGN_IN_CANCELLED')) {
        errorMessage = "Sign-in was cancelled.";
      } else if (e.toString().contains('concurrent-requests')) {
        errorMessage = "Another sign-in is in progress. Please wait.";
      } else {
        errorMessage = "Sign-in failed. Please try again.";
        print("Detailed error: $e");
      }
      
      Get.snackbar(
        "Error",
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
      print("Sign-in failed with error: $e");
    }
  }

  // Method to sign out (for future use)
  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      await _auth.signOut();
      print("User signed out successfully");
    } catch (e) {
      print("Error signing out: $e");
    }
  }
}
