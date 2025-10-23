import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    // Fallback to sign-in when Firestore has no user doc
    return const SignInScreen();
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


