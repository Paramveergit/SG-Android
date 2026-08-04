// ignore_for_file: file_names

import 'package:flutter/material.dart';

/// Design tokens for the retailer app - "Warehouse Ledger, Storefront"
/// variant. Same brand red and status language as the admin app (so a
/// customer recognizes "Shipped" the same way staff do), but warmer
/// neutrals and slightly softer edges since this is customer-facing,
/// not a staff back-office tool.
class AppColors {
  AppColors._();

  // Backgrounds - warm off-white instead of admin's graphite-white
  static const background = Color(0xFFFAF8F6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceBorder = Color(0xFFEAE5DF);
  static const surfaceMuted = Color(0xFFF3F0EC);

  // Text - warm near-black instead of pure graphite
  static const textPrimary = Color(0xFF211D1A);
  static const textSecondary = Color(0xFF8C8279);
  static const textOnBrand = Color(0xFFFFFFFF);

  // Brand - unchanged from admin app, this is the logo color
  static const brand = Color(0xFFB81F2E);
  static const brandDark = Color(0xFF8F1723);
  // Soft brand tint for highlights (flash sale tags, active states) -
  // gives the retailer app a bit of warmth admin doesn't need
  static const brandTintBg = Color(0xFFFBEEEE);
  static const brandTintFg = Color(0xFFB81F2E);

  // Status colors - identical to admin app so order status is a
  // consistent visual language across both apps
  static const pendingBg = Color(0xFFFFF4E5);
  static const pendingFg = Color(0xFFB26A00);

  static const processingBg = Color(0xFFF3EEFC);
  static const processingFg = Color(0xFF6A3FC4);

  static const shippedBg = Color(0xFFE8F0FE);
  static const shippedFg = Color(0xFF1A56C4);

  static const deliveredBg = Color(0xFFE6F4EA);
  static const deliveredFg = Color(0xFF1E7D34);

  static const cancelledBg = Color(0xFFFDEAEA);
  static const cancelledFg = Color(0xFFB3261E);

  // Warning / danger (distinct from brand red)
  static const warningBg = Color(0xFFFFF4E5);
  static const warningFg = Color(0xFFB26A00);
  static const dangerBg = Color(0xFFFDEAEA);
  static const dangerFg = Color(0xFFB3261E);

  // Success (order placed, payment confirmed, etc.)
  static const successBg = Color(0xFFE6F4EA);
  static const successFg = Color(0xFF1E7D34);
}
