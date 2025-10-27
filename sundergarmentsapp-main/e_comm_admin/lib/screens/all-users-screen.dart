// ignore_for_file: file_names, prefer_const_constructors, avoid_unnecessary_containers, avoid_print

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_comm_admin/utils/constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/get-all-user-length-controller.dart';
import '../models/user-model.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  final GetUserLengthController _getUserLengthController =
      Get.put(GetUserLengthController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppConstant.appTextColor,
        ),
        backgroundColor: AppConstant.appMainColor,
        title: Obx(() {
          return Text(
              'Users (${_getUserLengthController.userCollectionLength.toString()})',
              style: TextStyle(color: AppConstant.appTextColor),
            );
        }),
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdOn', descending: true)
            .get(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Container(
              child: Center(
                child: Text('Error occurred while fetching category!'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              child: Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          }
          if (snapshot.data!.docs.isEmpty) {
            return Container(
              child: Center(
                child: Text('No users found!'),
              ),
            );
          }

          if (snapshot.data != null) {
            return ListView.builder(
              shrinkWrap: true,
              physics: BouncingScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final data = snapshot.data!.docs[index];

                UserModel userModel = UserModel.fromMap(data.data() as Map<String, dynamic>);

                return Card(
                  elevation: 5,
                  child: ListTile(
                    // onTap: () => Get.to(
                    //   () => SpecificCustomerOrderScreen(
                    //       docId: snapshot.data!.docs[index]['uId'],
                    //       customerName: snapshot.data!.docs[index]
                    //           ['customerName']),
                    // ),

                    leading: CircleAvatar(
                      backgroundColor: AppConstant.appScendoryColor,
                      backgroundImage: _getUserImage(userModel.userImg),
                      child: _getUserImage(userModel.userImg) == null
                          ? Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            )
                          : null,
                    ),
                    title: Text(userModel.username),
                    subtitle: Text(userModel.email),
                    //trailing: Icon(Icons.edit),
                  ),
                );
              },
            );
          }

          return Container();
        },
      ),
    );
  }

  /// Safely gets the user image with proper error handling
  /// Returns null if no image URL is available or if there's an error
  ImageProvider? _getUserImage(String userImgUrl) {
    try {
      if (userImgUrl.isNotEmpty) {
        return CachedNetworkImageProvider(
          userImgUrl,
          errorListener: (err) {
            print('Error loading user image: $err');
          },
        );
      }
    } catch (e) {
      print('Error accessing user image: $e');
    }
    return null;
  }
}
