// ignore_for_file: file_names

import 'package:e_comm/screens/auth-ui/sign-in-screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/sign-up-controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final SignUpController signUpController = Get.put(SignUpController());
  TextEditingController username = TextEditingController();
  TextEditingController userEmail = TextEditingController();
  TextEditingController userPhone = TextEditingController();
  TextEditingController userCity = TextEditingController();
  TextEditingController userPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create account'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            TextFormField(
              controller: userEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: username,
              keyboardType: TextInputType.name,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: userPhone,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: userCity,
              keyboardType: TextInputType.streetAddress,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(
              () => TextFormField(
                controller: userPassword,
                obscureText: signUpController.isPasswordVisible.value,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      signUpController.isPasswordVisible.toggle();
                    },
                    icon: Icon(
                      signUpController.isPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  String name = username.text.trim();
                  String email = userEmail.text.trim();
                  String phone = userPhone.text.trim();
                  String city = userCity.text.trim();
                  String password = userPassword.text.trim();
                  String userDeviceToken = '';

                  if (name.isEmpty ||
                      email.isEmpty ||
                      phone.isEmpty ||
                      city.isEmpty ||
                      password.isEmpty) {
                    Get.snackbar(
                      'Error',
                      'Please enter all details',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.dangerFg,
                      colorText: AppColors.textOnBrand,
                    );
                  } else {
                    UserCredential? userCredential =
                        await signUpController.signUpMethod(
                      name,
                      email,
                      phone,
                      city,
                      password,
                      userDeviceToken,
                    );

                    if (userCredential != null) {
                      Get.snackbar(
                        'Verification email sent',
                        'Please check your email.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.successFg,
                        colorText: AppColors.textOnBrand,
                      );

                      FirebaseAuth.instance.signOut();
                      Get.offAll(() => SignInScreen());
                    }
                  }
                },
                child: const Text('Sign up'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                GestureDetector(
                  onTap: () => Get.offAll(() => SignInScreen()),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
