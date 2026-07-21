// ignore_for_file: file_names, unused_local_variable, unused_field, avoid_print

import 'package:e_comm/controllers/get-device-token-controller.dart';
import 'package:e_comm/screens/auth-ui/home-router.dart';
import 'package:e_comm/services/auth/google_auth_service.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

/// Thin wrapper kept so existing screens (welcome-screen.dart) don't need
/// to change. Delegates to the single canonical GoogleAuthService so
/// every entry point in the app produces the same Firebase UID for the
/// same Google account - this used to be a second, independent
/// implementation of the same flow, which is exactly what let the same
/// Google account resolve to two different Firebase UIDs depending on
/// whether someone signed in from the welcome screen or the sign-in
/// screen. See google_auth_service.dart for the full explanation.
class GoogleSignInController extends GetxController {
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  Future<void> signInWithGoogle() async {
    try {
      EasyLoading.show(status: "Signing in...");

      // Initialize device token controller if not already initialized
      GetDeviceTokenController getDeviceTokenController;
      try {
        getDeviceTokenController = Get.find<GetDeviceTokenController>();
      } catch (e) {
        getDeviceTokenController = Get.put(GetDeviceTokenController());
        // Wait a bit for the token to be generated
        await Future.delayed(const Duration(seconds: 2));
      }

      final userCredential = await _googleAuthService.signInWithGoogle(
        deviceToken: getDeviceTokenController.deviceToken,
      );

      EasyLoading.dismiss();

      if (userCredential?.user != null) {
        // Route through centralized home router for consistency
        Get.offAll(() => HomeRouter());
      } else {
        Get.snackbar(
          "Sign In Canceled",
          "Google sign in was canceled or no account was selected.",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      EasyLoading.dismiss();

      String errorMessage = "Sign-in failed. Please try again.";

      if (e.toString().contains('ApiException: 10') ||
          e.toString().contains('DEVELOPER_ERROR')) {
        errorMessage =
            "OAuth configuration error. Check SHA-1 fingerprint in Firebase Console.";
      } else if (e.toString().contains('ApiException: 12') ||
          e.toString().contains('SIGN_IN_REQUIRED')) {
        errorMessage = "Google Play Services not available or outdated.";
      } else if (e.toString().contains('ApiException: 7') ||
          e.toString().contains('NETWORK_ERROR')) {
        errorMessage = "Network error. Please check your internet connection.";
      } else if (e.toString().contains('cancelled') ||
          e.toString().contains('SIGN_IN_CANCELLED')) {
        errorMessage = "Sign-in was cancelled.";
      } else if (e.toString().contains('concurrent-requests')) {
        errorMessage = "Another sign-in is in progress. Please wait.";
      }

      Get.snackbar(
        "Error",
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
      print("Sign-in failed with error: $e");
    }
  }

  // Kept for backward compatibility with any existing callers.
  Future<void> signOut() async {
    await _googleAuthService.signOut();
  }
}
