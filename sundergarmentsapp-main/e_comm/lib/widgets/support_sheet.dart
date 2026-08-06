// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Help & Support bottom sheet - Call/WhatsApp/Email. Shared so Home
/// and Profile trigger the exact same sheet instead of two copies of
/// the same call/WhatsApp/email logic drifting apart over time.
void showSupportOptionsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.lg),
          topRight: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: AppColors.surfaceBorder,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Help & Support',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SupportOption(
            icon: Icons.phone,
            title: 'Call Us',
            subtitle: '+91 7850078100',
            onTap: () async {
              Get.back();
              final uri = Uri(scheme: 'tel', path: '+917850078100');
              if (!await launchUrl(uri)) {
                Get.snackbar(
                  'Couldn\'t open dialer',
                  'You can reach us at +91 7850078100',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
          ),
          _SupportOption(
            icon: Icons.message,
            title: 'WhatsApp',
            subtitle: 'Chat with us',
            onTap: () async {
              Get.back();
              final message = Uri.encodeComponent(
                  "Hi, I need help with my Sunder Garments order.");
              final uri =
                  Uri.parse('https://wa.me/917850078100?text=$message');
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                Get.snackbar(
                  'Couldn\'t open WhatsApp',
                  'Message us directly at +91 7850078100',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
          ),
          _SupportOption(
            icon: Icons.email,
            title: 'Email',
            subtitle: 'sundergarmentss@gmail.com',
            onTap: () async {
              Get.back();
              final uri = Uri(
                scheme: 'mailto',
                path: 'sundergarmentss@gmail.com',
                query: 'subject=${Uri.encodeComponent("Support request")}',
              );
              if (!await launchUrl(uri)) {
                Get.snackbar(
                  'Couldn\'t open mail app',
                  'Email us at sundergarmentss@gmail.com',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    ),
  );
}

class _SupportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.brandTintBg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: AppColors.brandTintFg, size: 20.0),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
