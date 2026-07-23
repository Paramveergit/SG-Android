// ignore_for_file: file_names, avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables, sized_box_for_whitespace

import 'dart:async';

import 'package:e_comm/controllers/get-user-data-controller.dart';
import 'package:e_comm/screens/admin-panel/admin-main-screen.dart';
import 'package:e_comm/screens/auth-ui/sign-in-screen.dart';
import 'package:e_comm/screens/user-panel/new-main-screen.dart';
import 'package:e_comm/utils/app-constant.dart';
import 'package:e_comm/widgets/animated-logo-widget.dart';
import 'package:e_comm/widgets/animated-text-widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // FIX: this used to be `User? user = FirebaseAuth.instance.currentUser;`
  // - a synchronous snapshot captured the instant this widget was
  // created, before Firebase had a chance to restore the persisted
  // session from local storage. Even though several seconds of splash
  // animation pass before this value is actually used below, the
  // null-or-not verdict was already locked in at that first frozen
  // instant. This is very likely why signing in never "stuck" - every
  // cold start could see null here even with a perfectly valid session
  // a moment away from being ready. No longer cached as a field; the
  // real current value is fetched right when _navigateToNextScreen
  // actually needs it, after authStateChanges() confirms Firebase has
  // finished restoring (or genuinely has no) session.
  late AnimationController _textController;
  late AnimationController _logoController;
  late AnimationController _fadeController;
  
  late Animation<double> _textScaleAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _showLogo = false;
  bool _showPoweredBy = false;
  bool _startTextAnimation = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Text animations
    _textScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    // Logo animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimationSequence() async {
    // Start text animation
    _textController.forward();
    
    // Start character animation after a short delay
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _startTextAnimation = true;
    });
    
    // Wait for text animation to complete (reduced from 2500ms)
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Start logo animation
    setState(() {
      _showLogo = true;
    });
    _logoController.forward();
    
    // Wait for logo animation to complete (reduced from 2500ms)
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Show powered by text
    setState(() {
      _showPoweredBy = true;
    });
    _fadeController.forward();
    
    // Wait for final animation and navigate (reduced from 1500ms)
    await Future.delayed(const Duration(milliseconds: 800));
    
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    final GetUserDataController getUserDataController =
        Get.put(GetUserDataController());

    // TEMPORARY DIAGNOSTIC - pinpointing why sign-in doesn't persist.
    // Gathers every relevant signal and shows them on screen, paused,
    // so it can be read/screenshotted instead of flashing past.
    final diagnostics = <String>[];
    User? syncUser;
    User? awaitedUser;
    bool googleSignedIn = false;
    String? googleEmail;
    String getUserDataResult = 'not attempted';

    try {
      syncUser = FirebaseAuth.instance.currentUser;
      diagnostics.add('currentUser (sync): ${syncUser?.uid ?? "null"}');
    } catch (e) {
      diagnostics.add('currentUser (sync) threw: $e');
    }

    try {
      awaitedUser = await FirebaseAuth.instance.authStateChanges().first
          .timeout(const Duration(seconds: 5));
      diagnostics.add('authStateChanges first: ${awaitedUser?.uid ?? "null"}');
    } catch (e) {
      diagnostics.add('authStateChanges threw/timed out: $e');
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      googleSignedIn = await googleSignIn.isSignedIn();
      final account = googleSignIn.currentUser;
      googleEmail = account?.email;
      diagnostics.add('GoogleSignIn.isSignedIn: $googleSignedIn (${googleEmail ?? "no cached account"})');
    } catch (e) {
      diagnostics.add('GoogleSignIn check threw: $e');
    }

    final User? user = awaitedUser ?? syncUser;

    if (user != null) {
      try {
        var userData = await getUserDataController.getUserData(user.uid);
        getUserDataResult = userData.isNotEmpty
            ? 'found profile, isAdmin=${userData[0]['isAdmin']}'
            : 'NO profile doc found for this uid';
      } catch (e) {
        getUserDataResult = 'threw: $e';
      }
    } else {
      getUserDataResult = 'skipped - user is null';
    }
    diagnostics.add('getUserData: $getUserDataResult');

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DiagnosticScreen(
          lines: diagnostics,
          onContinue: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    try {
      if (user != null) {
        // Fetch user data from Firestore
        var userData = await getUserDataController.getUserData(user!.uid);

        // Check if userData is not empty before accessing elements
        if (userData.isNotEmpty) {
          if (userData[0]['isAdmin'] == true) {
            Get.offAll(() => AdminMainScreen());
          } else {
            Get.offAll(() => NewMainScreen());
          }
        } else {
          // User exists in Firebase Auth but no data in Firestore, go to Sign-In
          Get.offAll(() => SignInScreen());
        }
      } else {
        // No user logged in, go to Sign-In
        Get.offAll(() => SignInScreen());
      }
    } catch (e) {
      // Don't leave the user stuck on the splash screen forever if
      // anything above fails (network issue, permissions, etc.) - fall
      // back to sign-in so they can at least retry.
      Get.snackbar(
        "Something went wrong",
        "Please try signing in again. ($e)",
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAll(() => SignInScreen());
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstant.appScendoryColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main content area
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Text Animation
                    if (!_showLogo)
                      AnimatedTextWidget(
                        text: AppConstant.appMainName,
                        scaleAnimation: _textScaleAnimation,
                        opacityAnimation: _textOpacityAnimation,
                        startAnimation: _startTextAnimation,
                        textStyle: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppConstant.appTextColor,
                          letterSpacing: 2.0,
                        ),
                      ),
                    
                    // Logo Animation
                    if (_showLogo)
                      AnimatedLogoWidget(
                        scaleAnimation: _logoScaleAnimation,
                        rotationAnimation: _logoRotationAnimation,
                        opacityAnimation: _logoScaleAnimation,
                      ),
                  ],
                ),
              ),
            ),
            
            // Powered by text
            if (_showPoweredBy)
              AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 40.0),
                      child: Text(
                        AppConstant.appPoweredBy,
                        style: TextStyle(
                          color: AppConstant.appTextColor.withOpacity(0.7),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// TEMPORARY DIAGNOSTIC SCREEN - remove once the login-persistence
/// bug is found and fixed. Shows every auth-related signal gathered
/// in _navigateToNextScreen, paused with a manual "Continue" button
/// so it can actually be read and screenshotted.
class _DiagnosticScreen extends StatelessWidget {
  final List<String> lines;
  final VoidCallback onContinue;

  const _DiagnosticScreen({
    required this.lines,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Auth Diagnostic',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    lines.map((l) => '• $l').join('\n\n'),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
