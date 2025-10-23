// ignore_for_file: file_names, sort_child_properties_last, prefer_const_constructors, unused_local_variable, must_be_immutable, avoid_print, unnecessary_string_interpolations, deprecated_member_use, unused_element, unnecessary_null_comparison
import 'package:e_comm_admin/screens/all-users-screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/all-orders-screen.dart';
import '../screens/all-products-screen.dart';
import '../screens/all_categories_screen.dart';
import '../screens/main-screen.dart';
import '../utils/constant.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: Get.height / 25),
      child: Drawer(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topRight: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        )),
        child: Wrap(
          runSpacing: 10,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              child: ListTile(
                titleAlignment: ListTileTitleAlignment.center,
                title: Text(
                  "Sunder Garments",
                  style: TextStyle(color: AppConstant.appTextColor),
                ),
                subtitle: Text(
                  "Version 1.0.1",
                  style: TextStyle(color: AppConstant.appTextColor),
                ),
                leading: CircleAvatar(
                  radius: 28.0, // Increased radius for better logo visibility
                  backgroundColor: AppConstant
                      .appMainColor, // Background color from AppConstant
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/SG_logo_admin.png', // Path to the Sundar Garments logo
                      fit: BoxFit.cover, // Ensures the logo fits properly within the circle
                      width: 50.0, // Matches the CircleAvatar size
                      height: 50.0,
                    ),
                  ),
                ),
              ),
            ),
            Divider(
              indent: 10.0,
              endIndent: 10.0,
              thickness: 1.5,
              color: Colors.grey,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ListTile(
                onTap: () {
                  Get.back();
                  Get.offAll(() => MainScreen());
                },
                title: Text(
                  'Home',
                  style: TextStyle(color: Colors.white),
                ),
                leading: Icon(
                  Icons.home_outlined,
                  color: Colors.white,
                ),
                trailing: Icon(
                  Icons.arrow_forward,
                  color: AppConstant.appTextColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ListTile(
                onTap: () {
                  Get.back();
                  Get.to(() => AllUsersScreen());
                },
                title: Text(
                  'Users',
                  style: TextStyle(color: Colors.white),
                ),
                leading: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
                trailing: Icon(
                  Icons.arrow_forward,
                  color: AppConstant.appTextColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ListTile(
                onTap: () {
                  Get.back();
                  Get.to(() => AllOrdersScreen());
                },
                title: Text(
                  'Orders',
                  style: TextStyle(color: Colors.white),
                ),
                leading: Icon(
                  Icons.shopping_bag,
                  color: Colors.white,
                ),
                trailing: Icon(
                  Icons.arrow_forward,
                  color: AppConstant.appTextColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ListTile(
                onTap: () {
                  Get.back();
                  Get.to(() => AllProductsScreen());
                },
                title: Text(
                  'Products',
                  style: TextStyle(color: Colors.white),
                ),
                leading: Icon(
                  Icons.production_quantity_limits,
                  color: Colors.white,
                ),
                trailing: Icon(
                  Icons.arrow_forward,
                  color: AppConstant.appTextColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ListTile(
                titleAlignment: ListTileTitleAlignment.center,
                onTap: () async {
                  Get.back();
                  Get.to(() => AllCategoriesScreen());
                },
                title: Text(
                  'Categories',
                  style: TextStyle(color: Colors.white),
                ),
                leading: Icon(
                  Icons.category,
                  color: Colors.white,
                ),
                trailing: Icon(
                  Icons.arrow_forward,
                  color: AppConstant.appTextColor,
                ),
              ),
            ),
          ],
        ),
        width: Get.width - 80.0,
        backgroundColor: AppConstant.appScendoryColor,
      ),
    );
  }
}
