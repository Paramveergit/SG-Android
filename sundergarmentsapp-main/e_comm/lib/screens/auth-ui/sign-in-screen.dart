// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, unused_local_variable, unnecessary_null_comparison, file_names

import 'package:e_comm/controllers/get-user-data-controller.dart';
import 'package:e_comm/controllers/sign-in-controller.dart';
import 'package:e_comm/controllers/auth_controller.dart';
import 'package:e_comm/screens/admin-panel/admin-main-screen.dart';
import 'package:e_comm/screens/auth-ui/email-auth-screen.dart';
import 'package:e_comm/screens/auth-ui/forget-password-screen.dart';
import 'package:e_comm/screens/auth-ui/sign-up-screen.dart';
import 'package:e_comm/screens/user-panel/main-screen.dart';
import 'package:e_comm/screens/auth-ui/home-router.dart';
import 'package:e_comm/utils/app-constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';

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
      backgroundColor: AppConstant.appScendoryColor,
      body: Stack(
        children: [
          // Background SG Logo with low transparency
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.1, // Very low transparency
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppConstant.appTextColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Main shopping bag icon
                      Icon(
                        Icons.shopping_bag,
                        size: 100,
                        color: AppConstant.appMainColor,
                      ),
                      
                      // Brand initials overlay
                      Positioned(
                        bottom: 20,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConstant.appMainColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'SG',
                            style: TextStyle(
                              color: AppConstant.appTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
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
                Text(
                  "Welcome to Sundar Garments",
                  style: TextStyle(
                    color: AppConstant.appTextColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 10),
                
                Text(
                  "Sign in to continue",
                  style: TextStyle(
                    color: AppConstant.appTextColor.withOpacity(0.8),
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
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          color: AppConstant.appTextColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: () async {
                            await authController.signInWithGoogle();
                          },
                          icon: Container(
                            width: 24,
                            height: 24,
                            child: Image.asset(
                              'assets/images/final-google-logo.png',
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                );
                              },
                            ),
                          ),
                          label: Text(
                            "Sign in with Google",
                            style: TextStyle(
                              color: AppConstant.appMainColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Email Sign In Button
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          color: AppConstant.appTextColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            // Navigate to our new email auth screen
                            Get.to(() => EmailAuthScreen());
                          },
                          icon: Icon(
                            Icons.email,
                            color: AppConstant.appMainColor,
                            size: 24,
                          ),
                          label: Text(
                            "Sign in with Email",
                            style: TextStyle(
                              color: AppConstant.appMainColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
                          color: AppConstant.appTextColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.offAll(() => SignUpScreen()),
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: AppConstant.appTextColor,
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

// Separate widget for email sign in form
class EmailSignInForm extends StatefulWidget {
  @override
  _EmailSignInFormState createState() => _EmailSignInFormState();
}

class _EmailSignInFormState extends State<EmailSignInForm> {
  final SignInController signInController = Get.put(SignInController());
  final GetUserDataController getUserDataController = Get.put(GetUserDataController());
  TextEditingController userEmail = TextEditingController();
  TextEditingController userPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstant.appScendoryColor,
      appBar: AppBar(
        backgroundColor: AppConstant.appScendoryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstant.appTextColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Email Sign In",
          style: TextStyle(color: AppConstant.appTextColor),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email field
            TextFormField(
              controller: userEmail,
              cursorColor: AppConstant.appTextColor,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: AppConstant.appTextColor),
              decoration: InputDecoration(
                hintText: "Email",
                hintStyle: TextStyle(color: AppConstant.appTextColor.withOpacity(0.6)),
                prefixIcon: Icon(Icons.email, color: AppConstant.appTextColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: AppConstant.appTextColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: AppConstant.appTextColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: AppConstant.appTextColor),
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Password field
            Obx(() => TextFormField(
              controller: userPassword,
              obscureText: signInController.isPasswordVisible.value,
              cursorColor: AppConstant.appTextColor,
              keyboardType: TextInputType.visiblePassword,
              style: TextStyle(color: AppConstant.appTextColor),
              decoration: InputDecoration(
                hintText: "Password",
                hintStyle: TextStyle(color: AppConstant.appTextColor.withOpacity(0.6)),
                prefixIcon: Icon(Icons.password, color: AppConstant.appTextColor),
                suffixIcon: GestureDetector(
                  onTap: () {
                    signInController.isPasswordVisible.toggle();
                  },
                  child: Icon(
                    signInController.isPasswordVisible.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppConstant.appTextColor,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: AppConstant.appTextColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: AppConstant.appTextColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: AppConstant.appTextColor),
                ),
              ),
            )),
            
            SizedBox(height: 10),
            
            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Get.to(() => ForgetPasswordScreen()),
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: AppConstant.appTextColor,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 30),
            
            // Sign in button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                color: AppConstant.appTextColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextButton(
                onPressed: () async {
                  String email = userEmail.text.trim();
                  String password = userPassword.text.trim();

                  if (email.isEmpty || password.isEmpty) {
                    Get.snackbar(
                      "Error",
                      "Please enter all details",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppConstant.appScendoryColor,
                      colorText: AppConstant.appTextColor,
                    );
                  } else {
                    UserCredential? userCredential = await signInController
                        .signInMethod(email, password);

                    if (userCredential != null) {
                      var userData = await getUserDataController
                          .getUserData(userCredential.user!.uid);

                      if (userCredential.user!.emailVerified) {
                        if (userData[0]['isAdmin'] == true) {
                          Get.snackbar(
                            "Success Admin Login",
                            "Login Successfully!",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppConstant.appScendoryColor,
                            colorText: AppConstant.appTextColor,
                          );
                          Get.offAll(() => AdminMainScreen());
                        } else {
                          // Route through centralized home router
                          Get.offAll(() => HomeRouter());
                          Get.snackbar(
                            "Success User Login",
                            "Login Successfully!",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppConstant.appScendoryColor,
                            colorText: AppConstant.appTextColor,
                          );
                        }
                      } else {
                        Get.snackbar(
                          "Error",
                          "Please verify your email before login",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppConstant.appScendoryColor,
                          colorText: AppConstant.appTextColor,
                        );
                      }
                    } else {
                      Get.snackbar(
                        "Error",
                        "Please try again",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppConstant.appScendoryColor,
                        colorText: AppConstant.appTextColor,
                      );
                    }
                  }
                },
                child: Text(
                  "SIGN IN",
                  style: TextStyle(
                    color: AppConstant.appMainColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
