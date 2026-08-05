// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../controllers/forget-password-controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final ForgetPasswordController forgetPasswordController =
      Get.put(ForgetPasswordController());
  TextEditingController userEmail = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Reset password'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              if (!isKeyboardVisible) ...[
                SizedBox(
                  height: 160,
                  child: Lottie.asset('assets/images/splash-icon.json'),
                ),
              ] else
                const SizedBox(height: AppSpacing.lg),
              const Text(
                'Enter the email on your account and we\'ll send you a link to reset your password.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: userEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final email = userEmail.text.trim();
                    if (email.isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Please enter your email',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.dangerFg,
                        colorText: AppColors.textOnBrand,
                      );
                    } else {
                      forgetPasswordController.ForgetPasswordMethod(email);
                    }
                  },
                  child: const Text('Send reset link'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
