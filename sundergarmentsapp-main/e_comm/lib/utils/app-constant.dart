// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Kept for backward compatibility - the ~35 files that reference
/// AppConstant.* still work unchanged. Values now point at the new
/// AppColors tokens instead of hardcoded hex, so there's one source
/// of truth. New code should use AppColors directly instead of adding
/// more references to this class.
class AppConstant {
  static String appMainName = 'Sunder Garments';
  static String appPoweredBy = 'Powered By SG';
  static const appMainColor = AppColors.brand;
  static const appScendoryColor = AppColors.brandDark;
  static const appTextColor = AppColors.textOnBrand;
  static const appStatusBarColor = AppColors.textOnBrand;
}
