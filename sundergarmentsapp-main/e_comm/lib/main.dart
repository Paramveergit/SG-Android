import 'package:e_comm/controllers/get-device-token-controller.dart';
import 'package:e_comm/controllers/auth_controller.dart';
import 'package:e_comm/firebase_options.dart';
import 'package:e_comm/screens/auth-ui/splash-screen.dart';
import 'package:e_comm/utils/app-constant.dart';
import 'package:e_comm/utils/auth_diagnostics.dart';
import 'package:e_comm/utils/performance_optimizer.dart';
import 'package:e_comm/utils/cache_manager.dart';
import 'package:e_comm/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Diagnostic capture: the actual currentUser state as early as
  // physically possible, before any of this app's own auth/routing
  // logic has run. If this is already null here, the persisted
  // session genuinely never made it into the native SDK by this
  // point - a completely different problem than a routing-side race,
  // and this is the one place that can tell the two apart.
  AuthDiagnostics.t0Uid = FirebaseAuth.instance.currentUser?.uid;
  AuthDiagnostics.t0Timestamp = DateTime.now();

  // Enable Firebase offline persistence for better performance
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize performance optimizer
  PerformanceOptimizer.init();

  // Initialize cache manager for better image performance
  CacheManager.limitCacheSize();

  // Initialize controllers
  Get.put(GetDeviceTokenController());
  Get.put(AuthController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstant.appMainName,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
      builder: EasyLoading.init(),
    );
  }
}
