// ignore_for_file: file_names, unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class GetUserDataController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Looks up a user by document ID directly (the users collection is
  /// keyed by uid), instead of a field-based `.where('uId', ...)` query.
  /// Direct document reads are evaluated simply and reliably by Firestore
  /// security rules; field-based queries combined with OR'd rule
  /// conditions are not reliably provable by Firestore's query validator
  /// and can be rejected even when the underlying access should be
  /// allowed. Returns a list (empty or one element) to keep the existing
  /// call sites (userData.isNotEmpty, userData[0]['isAdmin']) unchanged.
  Future<List<DocumentSnapshot<Object?>>> getUserData(String uId) async {
    final DocumentSnapshot<Object?> doc =
        await _firestore.collection('users').doc(uId).get();
    return doc.exists ? [doc] : [];
  }
}
