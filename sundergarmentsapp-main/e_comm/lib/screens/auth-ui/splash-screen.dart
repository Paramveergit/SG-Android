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
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  User? user = FirebaseAuth.instance.currentUser;
  
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

    if (user != null) {
      // Fetch user data from Firestore
      var userData = await getUserDataController.getUserData(user!.uid);

      // Check if userData is not empty before accessing elements
      if (userData != null && userData.isNotEmpty) {
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
