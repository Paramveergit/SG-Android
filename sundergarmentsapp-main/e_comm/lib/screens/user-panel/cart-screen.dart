// ignore_for_file: file_names, prefer_const_constructors, avoid_unnecessary_containers, prefer_const_literals_to_create_immutables, sized_box_for_whitespace, avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_comm/models/cart-model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:get/get.dart';

import '../../controllers/cart-price-controller.dart';
import '../../controllers/get-customer-device-token-controller.dart';
import '../../services/place-order-service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  final ProductPriceController productPriceController =
      Get.put(ProductPriceController());
  
  // Controllers for the bottom sheet form
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  
  // Variables for order placement
  String? customerToken;
  String? name;
  String? phone;
  String? address;

  @override
  void initState() {
    super.initState();
    _prefillFromSavedProfile();
  }

  // FIX: this used to ask for name/phone/address on every single order,
  // even though the person is already signed in with a real account.
  // Pre-fill from whatever's already saved on their profile, so most
  // returning customers see the sheet already filled in and can just
  // confirm instead of retyping the same details every time.
  Future<void> _prefillFromSavedProfile() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      // FIX: some accounts have "null" (the literal 4-character string,
      // from an old ?.toString() call on an actually-null value) stored
      // in Firestore instead of a genuinely empty value. isNotEmpty
      // alone doesn't catch that - "null" is a non-empty string as far
      // as Dart is concerned. Treat it the same as missing/empty so it
      // never shows up pre-filled in a form.
      String? clean(String? value) {
        final v = value?.trim();
        if (v == null || v.isEmpty) return null;
        if (v.toLowerCase() == 'null') return null;
        return v;
      }

      final savedName = clean(data['username'] as String?);
      final savedPhone = clean(data['phone'] as String?);
      final savedAddress = clean(data['userAddress'] as String?);
      if (savedName != null) {
        nameController.text = savedName;
      }
      if (savedPhone != null) {
        phoneController.text = savedPhone;
      }
      if (savedAddress != null) {
        addressController.text = savedAddress;
      }
    } catch (e) {
      // Non-fatal - if this fails, the sheet just opens blank like before.
      print('Could not pre-fill checkout details: $e');
    }
  }

  // Saves whatever the customer confirmed/typed back to their profile,
  // so the NEXT order pre-fills too, even if this was their first time
  // entering these details or they corrected something.
  Future<void> _saveDetailsToProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(
        {
          'username': name,
          'phone': phone,
          'userAddress': address,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      // Non-fatal - the order itself already succeeded by the time this
      // runs; failing to save the profile shouldn't block the user.
      print('Could not save checkout details to profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your cart'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('cart')
            .doc(user!.uid)
            .collection('cartOrders')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const AppErrorState(
              title: 'Could not load your cart',
              message: 'Please check your connection and try again.',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: Get.height / 5,
              child: const Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Add products to get started.',
            );
          }

          if (snapshot.data != null) {
            // Single in-memory sum from the snapshot's own docs - no
            // extra Firestore read needed, computed once per rebuild
            // instead of once per cart item.
            double cartTotal = 0.0;
            for (final doc in snapshot.data!.docs) {
              final total = doc['productTotalPrice'];
              if (total != null) {
                cartTotal += double.tryParse(total.toString()) ?? 0.0;
              }
            }
            productPriceController.totalPrice.value = cartTotal;

            return Container(
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final productData = snapshot.data!.docs[index];
                  CartModel cartModel = CartModel(
                    productId: productData['productId'],
                    categoryId: productData['categoryId'],
                    productName: productData['productName'],
                    categoryName: productData['categoryName'],
                    salePrice: productData['salePrice'],
                    fullPrice: productData['fullPrice'],
                    productImages: productData['productImages'],
                    deliveryTime: productData['deliveryTime'],
                    isSale: productData['isSale'],
                    productDescription: productData['productDescription'],
                    createdAt: productData['createdAt'],
                    updatedAt: productData['updatedAt'],
                    productQuantity: productData['productQuantity'],
                    productTotalPrice: double.parse(
                        productData['productTotalPrice'].toString()),
                  );

                  // FIX: this used to call productPriceController.
                  // fetchProductPrice() here, once per cart item, on
                  // every single rebuild - a cart with 10 items fired
                  // 10 redundant Firestore reads every time a quantity
                  // changed, all recomputing the exact same total this
                  // StreamBuilder's own snapshot already has. Compute
                  // it once, directly from the data already in hand,
                  // right after the snapshot builds below - no extra
                  // reads needed at all.
                  return SwipeActionCell(
                    key: ObjectKey(cartModel.productId),
                    trailingActions: [
                      SwipeAction(
                        title: "Delete",
                        forceAlignmentToBoundary: true,
                        performsFirstActionWithFullSwipe: true,
                        onTap: (CompletionHandler handler) async {
                          print('deleted');

                          await FirebaseFirestore.instance
                              .collection('cart')
                              .doc(user!.uid)
                              .collection('cartOrders')
                              .doc(cartModel.productId)
                              .delete();
                        },
                      )
                    ],
                    child: Card(
                      margin: const EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        bottom: AppSpacing.sm,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceMuted,
                          backgroundImage:
                              NetworkImage(cartModel.productImages[0]),
                        ),
                        title: Text(cartModel.productName),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '₹${cartModel.productTotalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(
                              width: Get.width / 20.0,
                            ),
                            // Delete button
                            GestureDetector(
                              onTap: () async {
                                await FirebaseFirestore.instance
                                    .collection('cart')
                                    .doc(user!.uid)
                                    .collection('cartOrders')
                                    .doc(cartModel.productId)
                                    .delete();
                                
                                Get.snackbar(
                                  'Success',
                                  'Item removed from cart',
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 2),
                                );
                              },
              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerBg,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: AppColors.dangerFg,
                                  size: 16,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: Get.width / 20.0,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.surfaceBorder,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Minus button
                                  GestureDetector(
                                    onTap: () async {
                                      if (cartModel.productQuantity > 1) {
                                        await FirebaseFirestore.instance
                                            .collection('cart')
                                            .doc(user!.uid)
                                            .collection('cartOrders')
                                            .doc(cartModel.productId)
                                            .update({
                                          'productQuantity':
                                              cartModel.productQuantity - 1,
                                          'productTotalPrice':
                                              (double.parse(cartModel.isSale ? cartModel.salePrice : cartModel.fullPrice) *
                                                  (cartModel.productQuantity - 1))
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: cartModel.productQuantity > 1 
                                            ? AppColors.textPrimary 
                                            : AppColors.surfaceMuted,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(3),
                                          bottomLeft: Radius.circular(3),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        color: cartModel.productQuantity > 1 
                                            ? AppColors.textOnBrand 
                                            : AppColors.textSecondary,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  // Quantity display/input
                                  GestureDetector(
                                    onTap: () {
                                      _showQuantityEditDialog(cartModel);
                                    },
                                    child: Container(
                                      width: 50,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: AppColors.surface,
                                        border: Border.symmetric(
                                          vertical: BorderSide(color: AppColors.surfaceBorder, width: 1.0),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          cartModel.productQuantity.toString(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.brand,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Plus button
                                  GestureDetector(
                                    onTap: () async {
                                      // Allow unlimited quantity increases for mass orders
                                      await FirebaseFirestore.instance
                                          .collection('cart')
                                          .doc(user!.uid)
                                          .collection('cartOrders')
                                          .doc(cartModel.productId)
                                          .update({
                                        'productQuantity':
                                            cartModel.productQuantity + 1,
                                        'productTotalPrice':
                                            (double.parse(cartModel.isSale ? cartModel.salePrice : cartModel.fullPrice) *
                                                (cartModel.productQuantity + 1))
                                      });
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.brand,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(3),
                                          bottomRight: Radius.circular(3),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: AppColors.textOnBrand,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return Container();
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      '₹${productPriceController.totalPrice.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: Get.width / 2.2,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    showCustomBottomSheet();
                  },
                  child: const Text('Checkout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuantityEditDialog(CartModel cartModel) {
    TextEditingController quantityController = TextEditingController(
      text: cartModel.productQuantity.toString(),
    );
    
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Edit Quantity',
          style: TextStyle(
            color: AppColors.brand,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cartModel.productName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.surfaceBorder,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Minus button
                  GestureDetector(
                    onTap: () {
                      int currentQty = int.tryParse(quantityController.text) ?? 1;
                      if (currentQty > 1) {
                        quantityController.text = (currentQty - 1).toString();
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(3),
                          bottomLeft: Radius.circular(3),
                        ),
                      ),
                      child: const Icon(
                        Icons.remove,
                        color: AppColors.textOnBrand,
                        size: 20,
                      ),
                    ),
                  ),
                  // Quantity input field
                  Container(
                    width: 80,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border.symmetric(
                        vertical: BorderSide(color: AppColors.surfaceBorder, width: 1.0),
                      ),
                    ),
                    child: TextFormField(
                      controller: quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                  // Plus button
                  GestureDetector(
                    onTap: () {
                      int currentQty = int.tryParse(quantityController.text) ?? 1;
                      quantityController.text = (currentQty + 1).toString();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(3),
                          bottomRight: Radius.circular(3),
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.textOnBrand,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              int newQuantity = int.tryParse(quantityController.text) ?? 1;
              if (newQuantity >= 1) {
                double newTotalPrice = double.parse(
                  cartModel.isSale ? cartModel.salePrice : cartModel.fullPrice,
                ) * newQuantity;
                
                await FirebaseFirestore.instance
                    .collection('cart')
                    .doc(user!.uid)
                    .collection('cartOrders')
                    .doc(cartModel.productId)
                    .update({
                  'productQuantity': newQuantity,
                  'productTotalPrice': newTotalPrice,
                });
                
                Get.back();
                
                Get.snackbar(
                  'Success',
                  'Quantity updated successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Quantity must be at least 1',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              }
            },
            child: Text(
              'Update',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void showCustomBottomSheet() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Delivery details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: phoneController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text != '' &&
                      phoneController.text != '' &&
                      addressController.text != '') {
                    name = nameController.text.trim();
                    phone = phoneController.text.trim();
                    address = addressController.text.trim();
                    customerToken = await getCustomerDeviceToken();

                    placeOrder(
                      context: context,
                      customerName: name!,
                      customerPhone: phone!,
                      customerAddress: address!,
                      customerDeviceToken: customerToken!,
                    );

                    // Save these details for next time, so the sheet
                    // pre-fills automatically on future orders.
                    _saveDetailsToProfile(
                      name: name!,
                      phone: phone!,
                      address: address!,
                    );
                  } else {
                    print("Fill The Details");
                  }
                },
                child: Text(
                  "Place order",
                  style: TextStyle(color: AppColors.textOnBrand),
                ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      elevation: 6,
    );
  }
}
