// ignore_for_file: camel_case_types, file_names, unnecessary_overrides, unused_local_variable, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class bannerController extends GetxController {
  RxList<String> bannerUrls = RxList<String>([]);
  RxBool isLoading = true.obs;
  RxBool hasError = false.obs;
  RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBannersUrls();
  }

  //fetch banners
  Future<void> fetchBannersUrls() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      
      QuerySnapshot bannersSnapshot =
          await FirebaseFirestore.instance.collection('banners').get();

      if (bannersSnapshot.docs.isNotEmpty) {
        bannerUrls.value = bannersSnapshot.docs
            .map((doc) => doc['imageUrl'] as String)
            .toList();
        
        // Update UI after successful fetch
        update(['banners']);
      } else {
        // No banners found
        bannerUrls.clear();
        hasError.value = true;
        errorMessage.value = 'No banners available';
      }
    } catch (e) {
      print("Banner fetch error: $e");
      hasError.value = true;
      errorMessage.value = 'Failed to load banners';
      bannerUrls.clear();
    } finally {
      isLoading.value = false;
      update(['banners']);
    }
  }

  // Refresh banners
  Future<void> refreshBanners() async {
    await fetchBannersUrls();
  }

  // Check if banners are available
  bool get hasBanners => bannerUrls.isNotEmpty;
  
  // Get banner count
  int get bannerCount => bannerUrls.length;
}




