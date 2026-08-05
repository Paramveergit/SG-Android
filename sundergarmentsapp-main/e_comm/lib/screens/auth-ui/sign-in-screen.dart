// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, unused_local_variable, unnecessary_null_comparison, file_names

import 'package:e_comm/controllers/auth_controller.dart';
import 'package:e_comm/screens/auth-ui/email-auth-screen.dart';
import 'package:e_comm/screens/auth-ui/sign-up-screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandDark,
      body: Stack(
        children: [
          // Background SG mark, low opacity
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.08,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.textOnBrand,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag,
                        size: 100,
                        color: AppColors.brand,
                      ),
                      Positioned(
                        bottom: 20,
                        child: Text(
                          'SG',
                          style: TextStyle(
                            color: AppColors.brand,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top spacing
                SizedBox(height: Get.height * 0.15),
                
                // Welcome text
                const Text(
                  "Welcome to Sunder Garments",
                  style: TextStyle(
                    color: AppColors.textOnBrand,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 10),
                
                Text(
                  "Sign in to continue",
                  style: TextStyle(
                    color: AppColors.textOnBrand.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Spacing before buttons
                SizedBox(height: Get.height * 0.2),
                
                // Sign in buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      // Google Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await authController.signInWithGoogle();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.brand,
                          ),
                          icon: SizedBox(
                            width: 20,
                            height: 20,
                            child: Image.asset(
                              'assets/images/final-google-logo.png',
                              errorBuilder: (context, error, stackTrace) {
                                return const Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brand,
                                  ),
                                );
                              },
                            ),
                          ),
                          label: const Text(
                            "Sign in with Google",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Get.to(() => EmailAuthScreen());
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textOnBrand,
                            side: const BorderSide(color: AppColors.textOnBrand),
                          ),
                          icon: const Icon(Icons.email_outlined, size: 22),
                          label: const Text(
                            "Sign in with email",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom spacing
                Spacer(),
                
                // Sign up link
                Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppColors.textOnBrand.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.offAll(() => SignUpScreen()),
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            color: AppColors.textOnBrand,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
