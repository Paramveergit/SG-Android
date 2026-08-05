import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin-panel/admin-main-screen.dart';
import '../auth-ui/sign-in-screen.dart';
import '../user-panel/new-main-screen.dart';
import '../../controllers/get-user-data-controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_error_state.dart';

/// Centralized post-auth router.
/// Decides which home screen to show while keeping the rest of the app unchanged.
class HomeRouter extends StatefulWidget {
  const HomeRouter({super.key});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  late Future<_RouteResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _decideNext();
  }

  Future<_RouteResult> _decideNext() async {
    // FIX: FirebaseAuth.instance.currentUser is a synchronous snapshot
    // that can genuinely be null for a moment on app cold start, before
    // Firebase finishes restoring the persisted session from local
    // storage. Checking it immediately - as this code used to - can
    // wrongly conclude "not signed in" and bounce to Sign-In even
    // though a valid session exists a beat later. Waiting for the
    // first real auth-state event removes that race entirely.
    final User? user = await FirebaseAuth.instance.authStateChanges().first;
    if (user == null) {
      return _RouteResult.widget(const SignInScreen());
    }

    try {
      // Use existing controller to keep logic consistent with SplashScreen
      final GetUserDataController getUserDataController = Get.put(GetUserDataController());
      final userData = await getUserDataController.getUserData(user.uid);

      if (userData.isNotEmpty) {
        if (userData[0]['isAdmin'] == true) {
          return _RouteResult.widget(const AdminMainScreen());
        }
        return _RouteResult.widget(const NewMainScreen());
      }

      // User is authenticated with Firebase but has no profile doc yet.
      // This used to bounce them straight back to Sign-In, which looked
      // like their account had vanished. Self-heal instead: create a
      // minimal profile from what Firebase Auth already knows, then let
      // them in. Covers slow writes, dropped connections, and old
      // accounts created before this doc was required.
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
      return _RouteResult.widget(const NewMainScreen());
    } catch (e, stackTrace) {
      // FIX: this used to silently swallow the real error and always
      // fall back to SignInScreen - which is exactly what "I have to
      // log in with Google every time I open the app" looks and feels
      // like to a user, even when their Firebase session is perfectly
      // valid. The actual cause (a permission error, a missing index,
      // a genuine network failure, anything) was never visible to
      // anyone. Show it instead of hiding it.
      debugPrint('=== HomeRouter: profile lookup failed ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('==========================================');
      return _RouteResult.error(e.toString());
    }
  }

  void _retry() {
    setState(() {
      _future = _decideNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RouteResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final result = snapshot.data;

        if (result != null && result.errorMessage != null) {
          return _HomeRouterErrorScreen(
            error: result.errorMessage!,
            onRetry: _retry,
          );
        }

        final next = result?.widget;
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

class _RouteResult {
  final Widget? widget;
  final String? errorMessage;
  _RouteResult.widget(this.widget) : errorMessage = null;
  _RouteResult.error(this.errorMessage) : widget = null;
}

/// Shown when something genuinely fails while loading the account after
/// sign-in - instead of silently forcing a fresh Google sign-in, this
/// tells the person (and whoever is debugging with them) what actually
/// went wrong, with a way to retry or fall back to signing in again.
class _HomeRouterErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _HomeRouterErrorScreen({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppErrorState(
                title: 'Could not load your account',
                message: error,
                onRetry: onRetry,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Get.offAll(() => const SignInScreen());
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
