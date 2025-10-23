import 'package:e_comm/controllers/get-device-token-controller.dart';
import 'package:e_comm/controllers/auth_controller.dart';
import 'package:e_comm/firebase_options.dart';
import 'package:e_comm/screens/auth-ui/splash-screen.dart';
import 'package:e_comm/utils/app-constant.dart';
import 'package:e_comm/utils/performance_optimizer.dart';
import 'package:e_comm/utils/cache_manager.dart';
import 'package:e_comm/theme/app_theme.dart';
import 'package:e_comm/theme/theme_bridge.dart';
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
  
  // Enable Firebase offline persistence for better performance
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // Initialize theme bridge
  ThemeBridge.init();
  
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
      // Use the theme bridge to maintain backward compatibility
      theme: ThemeBridge.theme,
      // Keep the app's original look and feel
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
      builder: EasyLoading.init(),
    );
  }
}
