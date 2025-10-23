// Welcome Popup Controller
// Manages the welcome popup that appears only once when the app is opened

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WelcomePopupController extends GetxController {
  final _storage = GetStorage();
  final _user = FirebaseAuth.instance.currentUser;
  
  RxBool shouldShowWelcome = false.obs;
  RxBool isShowingWelcome = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkWelcomeStatus();
  }

  /// Check if welcome popup should be shown
  void _checkWelcomeStatus() {
    if (_user == null) return;
    
    final String userId = _user!.uid;
    final String welcomeKey = 'welcome_shown_$userId';
    
    // Check if welcome has been shown for this user
    final bool hasShownWelcome = _storage.read(welcomeKey) ?? false;
    
    if (!hasShownWelcome) {
      shouldShowWelcome.value = true;
    }
  }

  /// Show the welcome popup
  void showWelcomePopup() {
    if (shouldShowWelcome.value && !isShowingWelcome.value) {
      isShowingWelcome.value = true;
    }
  }

  /// Mark welcome as shown and hide popup
  void markWelcomeAsShown() {
    if (_user != null) {
      final String userId = _user!.uid;
      final String welcomeKey = 'welcome_shown_$userId';
      
      // Mark as shown in storage
      _storage.write(welcomeKey, true);
      
      // Update state
      shouldShowWelcome.value = false;
      isShowingWelcome.value = false;
    }
  }

  /// Get user display name
  String get userDisplayName {
    return _user?.displayName ?? 'Dear Customer';
  }

  /// Get user email
  String? get userEmail {
    return _user?.email;
  }

  /// Get user photo URL
  String? get userPhotoURL {
    return _user?.photoURL;
  }

  /// Check if user is logged in
  bool get isUserLoggedIn {
    return _user != null;
  }

  /// Reset welcome status (for testing)
  void resetWelcomeStatus() {
    if (_user != null) {
      final String userId = _user!.uid;
      final String welcomeKey = 'welcome_shown_$userId';
      
      _storage.remove(welcomeKey);
      shouldShowWelcome.value = true;
      isShowingWelcome.value = false;
    }
  }
}



