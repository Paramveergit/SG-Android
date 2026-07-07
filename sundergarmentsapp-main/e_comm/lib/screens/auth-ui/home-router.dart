import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin-panel/admin-main-screen.dart';
import '../auth-ui/sign-in-screen.dart';
import '../user-panel/new-main-screen.dart';
import '../../controllers/get-user-data-controller.dart';

/// Centralized post-auth router.
/// Decides which home screen to show while keeping the rest of the app unchanged.
class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  Future<Widget> _decideNext() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SignInScreen();
    }

    // Use existing controller to keep logic consistent with SplashScreen
    final GetUserDataController getUserDataController = Get.put(GetUserDataController());
    final userData = await getUserDataController.getUserData(user.uid);

    if (userData != null && userData.isNotEmpty) {
      if (userData[0]['isAdmin'] == true) {
        return const AdminMainScreen();
      }
      return const NewMainScreen();
    }

    // User is authenticated with Firebase but has no profile doc yet.
    // This used to bounce them straight back to Sign-In, which looked
    // like their account had vanished. Self-heal instead: create a
    // minimal profile from what Firebase Auth already knows, then let
    // them in. Covers slow writes, dropped connections, and old
    // accounts created before this doc was required.
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uId': user.uid,
        'username': user.displayName ?? '',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'userImg': user.photoURL ?? '',
        'userDeviceToken': '',
        'country': '',
        'userAddress': '',
        'street': '',
        'isAdmin': false,
        'isActive': true,
        'createdOn': DateTime.now(),
        'city': '',
      }, SetOptions(merge: true));
      return const NewMainScreen();
    } catch (_) {
      // Firestore is genuinely unreachable (offline, etc.) — only now
      // is Sign-In actually the right fallback.
      return const SignInScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _decideNext(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final next = snapshot.data;
        // Use Get to replace current route to avoid stacking
        // but still return a minimal widget immediately
        // The navigation is scheduled to run after build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (next != null) {
            Get.offAll(() => next);
          }
        });
        return const SizedBox.shrink();
      },
    );
  }
}


