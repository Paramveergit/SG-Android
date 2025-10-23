// ignore_for_file: file_names, unused_field, body_might_complete_normally_nullable, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../utils/constant.dart';

class SignInController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //for password visibilty
  var isPasswordVisible = false.obs;

  Future<UserCredential?> signInMethod(
      String userEmail, String userPassword) async {
    try {
      EasyLoading.show(status: "Please wait");
      
      print("🔍 DEBUG: Starting authentication for email: $userEmail");
      print("🔍 DEBUG: Firebase Auth instance: ${_auth.app.name}");
      print("🔍 DEBUG: Current user before login: ${_auth.currentUser?.email}");
      
      // Check if user exists in Firestore first
      try {
        QuerySnapshot userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();
        
        if (userQuery.docs.isEmpty) {
          print("❌ DEBUG: No user found in Firestore with email: $userEmail");
          Get.snackbar(
            "Error",
            "No admin account found with this email. Please sign up first.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppConstant.appScendoryColor,
            colorText: AppConstant.appTextColor,
            duration: Duration(seconds: 5),
          );
          EasyLoading.dismiss();
          return null;
        } else {
          print("✅ DEBUG: User found in Firestore: ${userQuery.docs.first.data()}");
        }
      } catch (e) {
        print("⚠️ DEBUG: Error checking Firestore: $e");
      }
      
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: userEmail,
        password: userPassword,
      );

      print("✅ DEBUG: Authentication successful for: ${userCredential.user?.email}");
      print("✅ DEBUG: User ID: ${userCredential.user?.uid}");
      print("✅ DEBUG: Email verified: ${userCredential.user?.emailVerified}");
      
      EasyLoading.dismiss();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      EasyLoading.dismiss();
      
      print("❌ DEBUG: Firebase Auth Exception - Code: ${e.code}");
      print("❌ DEBUG: Firebase Auth Exception - Message: ${e.message}");
      print("❌ DEBUG: Firebase Auth Exception - Full: $e");
      
      // Provide more specific error messages
      String errorMessage = "Authentication failed";
      
      switch (e.code) {
        case 'invalid-credential':
          errorMessage = "Invalid email or password. Please check your credentials.";
          break;
        case 'user-not-found':
          errorMessage = "No user found with this email address. Please sign up first.";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password. Please try again.";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many failed attempts. Please try again later.";
          break;
        case 'operation-not-allowed':
          errorMessage = "Email/password sign-in is not enabled for this app.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email format.";
          break;
        case 'weak-password':
          errorMessage = "Password is too weak.";
          break;
        case 'email-already-in-use':
          errorMessage = "Email is already registered.";
          break;
        default:
          errorMessage = "Authentication error: ${e.message}";
      }
      
      Get.snackbar(
        "Error",
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.appScendoryColor,
        colorText: AppConstant.appTextColor,
        duration: Duration(seconds: 5),
      );
      
      print("Firebase Auth Error: ${e.code} - ${e.message}");
    } catch (e) {
      EasyLoading.dismiss();
      print("❌ DEBUG: Unexpected Error: $e");
      print("❌ DEBUG: Error type: ${e.runtimeType}");
      
      Get.snackbar(
        "Error",
        "An unexpected error occurred: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.appScendoryColor,
        colorText: AppConstant.appTextColor,
      );
      print("Unexpected Error: $e");
    }
  }
}
