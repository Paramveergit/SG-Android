// ignore_for_file: file_names, unnecessary_overrides, unused_local_variable, avoid_print

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import '../utils/app-constant.dart';

class GetDeviceTokenController extends GetxController {
  String? deviceToken;

  @override
  void onInit() {
    super.onInit();
    _requestPermissionAndGetToken();
  }

  Future<void> _requestPermissionAndGetToken() async {
    // FIX: notifications were never actually requested - getToken()
    // alone still succeeds and returns a valid device token regardless
    // of notification permission, which is exactly why this looked
    // like it was working (the token existed, got saved, Cloud
    // Functions could send to it) while every notification was
    // silently suppressed by the OS on Android 13+ (API 33+), which
    // requires an explicit runtime grant before ANY notification can
    // display at all. requestPermission() triggers that system
    // prompt - also correctly handles iOS the same way once that
    // platform is built, since this is shared Dart code.
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('Notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      print('Notification permission request failed: $e');
      // Don't block token fetch on this - a denied/failed permission
      // request shouldn't prevent the app from working, it just means
      // notifications won't display until the person enables them
      // from system settings.
    }

    await getDeviceToken();
  }

  Future<void> getDeviceToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        deviceToken = token;
        print("token : $deviceToken");
        update();
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "$e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.appScendoryColor,
        colorText: AppConstant.appTextColor,
      );
    }
  }
}