// import 'dart:math';
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:dms/common/widgets/appbar/appbar.dart';
// import 'package:dms/utils/constants/colors.dart';
// import 'package:dms/utils/helpers/helper_fuctions.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../../../services/firestore.dart';
// import 'models/shop_model.dart';
// import 'my_orders_page.dart';
//
// class CartPage extends StatefulWidget {
//   final String userId;
//   final String shopId;
//
//   CartPage({required this.userId, required this.shopId});
//
//   @override
//   _CartPageState createState() => _CartPageState();
// }
//
// class _CartPageState extends State<CartPage> {
//   final FireStoreServices _firestoreService = FireStoreServices();
//   String? selectedTableNumber;
//   List<Map<String, dynamic>> tableOptions = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchTableOptions();
//     _fetchCoupons();
//
//   }
//
//   Future<void> _fetchTableOptions() async {
//     DocumentSnapshot docSnapshot =
//     await FirebaseFirestore.instance.collection('shops').doc(widget.shopId).get();
//     // Example shop model assuming numberOfTables is a field in your shop document
//     // Adjust this based on your actual shop document structure
//     int numberOfTables = docSnapshot.get('numberOfTables') ?? 0;
//     List<Map<String, dynamic>> options = List.generate(numberOfTables, (index) {
//       return {
//         'number': 'Table ${index + 1}',
//         'icon': Icons.table_chart,
//       };
//     });
//
//     setState(() {
//       tableOptions = options;
//     });
//   }
//
//   Future<void> _fetchCoupons() async {
//     try {
//       // Query the subcollection 'coupons' inside the shop document
//       QuerySnapshot couponsSnapshot = await FirebaseFirestore.instance
//           .collection('shops')
//           .doc(widget.shopId)
//           .collection('coupons')
//           .get();
//
//       // Initialize list to store coupons
//       List<Map<String, dynamic>> couponsList = [];
//
//       // Process snapshot if data exists
//       if (couponsSnapshot.docs.isNotEmpty) {
//         couponsList = couponsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
//       }
//
//       // Update state with fetched coupon codes
//       setState(() {
//         couponCodes = couponsList;
//       });
//     } catch (error) {
//       print("Error fetching coupons: $error");
//     }
//   }
//
//
//   List<Map<String, dynamic>> couponCodes = [];
//   String selectedCoupon = ''; // Placeholder for selected coupon code
//   int discountPercentage = 0;
//   int maxDiscountRupees = 0;
//   int totalBill = 0;
//
//   @override
//   Widget build(BuildContext context) {
//     bool dark = SMAHelperFunctions.isDarkMode(context);
//     return Scaffold(
//       appBar: SMAAppBar(
//         title: Text('Cart'),
//       ),
//       body: StreamBuilder<DocumentSnapshot>(
//         stream: _firestoreService.getCartItems(widget.userId),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//
//           if (!snapshot.hasData) {
//             return Center(child: Text('No data found.'));
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text('An error occurred.'));
//           }
//
//           Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
//           List cartItems = userData['cart'] ?? [];
//
//           if (cartItems.isEmpty) {
//             return Center(child: Text('Cart is empty.'));
//           }
//
//           int totalBill = 0;
//           for (var item in cartItems) {
//             // Calculate the subtotal for each item (price * quantity)
//             double subtotal = item['price'] * item['quantity'];
//             totalBill += subtotal.toInt();
//           }
//
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: cartItems.length,
//                   itemBuilder: (context, index) {
//                     var item = cartItems[index];
//                     return ListTile(
//                       leading: _buildPhoto(item['imageUrl']),
//                       title: Text(item['name']),
//                       subtitle: Text('₹ ${item['price'].toString()}'),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(item['quantity'].toString()),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//
//                     if (selectedCoupon.isNotEmpty)
//                       Container(
//                         color: dark ? SMAColors.darkContainer : SMAColors.lightContainer,
//                         padding: EdgeInsets.all(10),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Coupon Applied: $selectedCoupon',
//                               style: TextStyle(fontSize: 16),
//                             ),
//                             TextButton(
//                               onPressed: () {
//                                 setState(() {
//                                   selectedCoupon = '';
//                                 });
//                               },
//                               child: Text(
//                                 'Remove',
//                                 style: TextStyle(
//                                   color: Colors.red,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     Text(
//                       'Available Coupons',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     _buildCouponsList(),
//                     SizedBox(height: 10),
//                     Text(
//                       'Total: ₹$totalBill',
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(height: 10),
//                     selectedCoupon != ""
//                         ?Text(
//                       'Discounted Total: ₹${calculateDiscountedTotal()}',
//                       style: TextStyle(fontSize: 18),
//                     ): SizedBox.shrink(),
//                     SizedBox(height: 20),
//                     Text(
//                       'Select Table Number:',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(height: 10),
//                     DropdownButtonFormField<String>(
//                       value: selectedTableNumber,
//                       icon: Icon(Icons.arrow_drop_down),
//                       iconSize: 24,
//                       elevation: 16,
//                       isExpanded: true,
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           selectedTableNumber = newValue;
//                         });
//                       },
//                       items: tableOptions.map<DropdownMenuItem<String>>((option) {
//                         return DropdownMenuItem<String>(
//                           value: option['number'],
//                           child: Row(
//                             children: [
//                               Icon(option['icon']),
//                               SizedBox(width: 10),
//                               Text(option['number']),
//                             ],
//                           ),
//                         );
//                       }).toList(),
//                       decoration: InputDecoration(
//                         border: OutlineInputBorder(),
//                         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: selectedTableNumber != null
//                           ? () {
//                         _showPaymentOptions(context);
//                       }
//                           : null,
//                       child: Text('Place Order'),
//                       style: ElevatedButton.styleFrom(
//                         padding: EdgeInsets.symmetric(vertical: 15),
//                         textStyle: TextStyle(fontSize: 18),
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                     Divider(height: 2, color: Colors.grey),
//                     SizedBox(height: 10),
//
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildPhoto(imageUrl) {
//     if (imageUrl != null && imageUrl.isNotEmpty) {
//       return CachedNetworkImage(
//         imageUrl: imageUrl,
//         placeholder: (context, url) => Center(
//           child: CircularProgressIndicator(),
//         ),
//         errorWidget: (context, url, error) {
//           print('Error loading image: $error');
//           return Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.image, color: Colors.red,),
//             ],
//           );
//         },
//         fit: BoxFit.cover,
//         width: 60.0,
//         height: 60.0,
//       );
//     } else {
//       return SizedBox.shrink();
//     }
//   }
//
//   Widget _buildCouponsList() {
//     return SizedBox(
//       height: 150, // Adjust the height as needed
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: couponCodes.length,
//         itemBuilder: (context, index) {
//           var coupon = couponCodes[index];
//           return Card(
//             margin: EdgeInsets.all(8),
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('${coupon['code']}'),
//                   Text('Discount: ${coupon['percentage']}%'),
//                   Text('Max Discount: ₹${coupon['maxRupees']}'),
//                   TextButton(
//                     onPressed: () {
//                       setState(() {
//                         selectedCoupon = coupon['code'];
//                         discountPercentage = coupon['percentage'];
//                         maxDiscountRupees = coupon['maxRupees'];
//                       });
//                     },
//                     child: Text('Apply'),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   int calculateDiscountedTotal() {
//     int discountedTotal = totalBill;
//
//     if (discountPercentage > 0) {
//       // Calculate the discount amount
//       int discountAmount = (totalBill * discountPercentage / 100).round();
//
//       // Apply the maximum allowed discount if needed
//       if (discountAmount > maxDiscountRupees) {
//         discountAmount = maxDiscountRupees;
//       }
//
//       // Subtract the discount amount from the total bill
//       discountedTotal = totalBill - discountAmount;
//     }
//
//     return discountedTotal;
//   }
//
//
//   void _showPaymentOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (BuildContext context) {
//         return Container(
//           height: MediaQuery.of(context).size.height * 0.9,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Choose Payment Option',
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 20),
//                 ListTile(
//                   leading: Icon(Icons.credit_card),
//                   title: Text('Credit Card'),
//                   onTap: () {
//                     _processPayment(context, 'Credit Card');
//                   },
//                 ),
//                 ListTile(
//                   leading: Icon(Icons.credit_card),
//                   title: Text('Debit Card'),
//                   onTap: () {
//                     _processPayment(context, 'Debit Card');
//                   },
//                 ),
//                 ListTile(
//                   leading: Icon(Icons.account_balance_wallet),
//                   title: Text('UPI'),
//                   onTap: () {
//                     _processPayment(context, 'UPI');
//                   },
//                 ),
//                 ListTile(
//                   leading: Icon(Icons.money),
//                   title: Text('Cash'),
//                   onTap: () {
//                     _processPayment(context, 'Cash');
//                   },
//                 ),
//                 Spacer(),
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   child: Text('Cancel'),
//                   style: ElevatedButton.styleFrom(
//                     padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
//                     textStyle: TextStyle(fontSize: 18),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//
//   void _processPayment(BuildContext context, String paymentMethod) async {
//     Navigator.pop(context);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Processing $paymentMethod payment...')),
//     );
//
//     // Retrieve cart data
//     DocumentSnapshot cartSnapshot = await _firestoreService.getCartItems(widget.userId).first;
//     if (!cartSnapshot.exists) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Cart is empty. No order placed.')),
//       );
//       return;
//     }
//
//     Map<String, dynamic> userData = cartSnapshot.data() as Map<String, dynamic>;
//     List cartItems = userData['cart'] ?? [];
//     int totalBill = calculateDiscountedTotal();
//
//     // Prepare order data
//     Map<String, dynamic> orderData = {
//       'userId': widget.userId,
//       'shopId': widget.shopId,
//       'items': cartItems,
//       'totalBill': totalBill,
//       'tableNumber': selectedTableNumber ?? 'Not selected',
//       'paymentMethod': paymentMethod,
//       'status': 'Order Accepted',
//       'estimatedWaitTime': '14 minutes',
//       'createdAt': Timestamp.now(),
//     };
//
//     try {
//       // Add order to Firestore
//       DocumentReference orderRef = await FirebaseFirestore.instance.collection('orders').add(orderData);
//
//       // Clear cart
//       await _firestoreService.clearCart(widget.userId);
//
//       // Update status and estimated wait time
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Order placed successfully. Estimated wait time: 30 minutes.')),
//       );
//
//       // Navigate to MyOrdersPage after successful order placement
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => MyOrdersPage(userId: widget.userId)),
//       );
//     } catch (error) {
//       print('Error placing order: $error');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to place order. Please try again later.')),
//       );
//     }
//   }
//
// }
//
//
//
//
//
//

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'my_orders_page.dart';

class CartPage extends StatefulWidget {
  final String userId;
  final String shopId;

  CartPage({required this.userId, required this.shopId});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedTableNumber;
  List<Map<String, dynamic>> tableOptions = [];
  List<Map<String, dynamic>> couponCodes = [];
  String selectedCoupon = '';
  int discountPercentage = 0;
  int maxDiscountRupees = 0;
  int totalBill = 0;

  @override
  void initState() {
    super.initState();
    _fetchTableOptions();
    _fetchCoupons();
  }

  Future<void> _fetchTableOptions() async {
    DocumentSnapshot docSnapshot =
    await _firestore.collection('shops').doc(widget.shopId).get();
    int numberOfTables = docSnapshot.get('numberOfTables') ?? 0;
    List<Map<String, dynamic>> options =
    List.generate(numberOfTables, (index) {
      return {
        'number': 'Table ${index + 1}',
        'icon': Icons.table_chart,
      };
    });

    setState(() {
      tableOptions = options;
    });
  }

  Future<void> _fetchCoupons() async {
    try {
      QuerySnapshot couponsSnapshot = await _firestore
          .collection('shops')
          .doc(widget.shopId)
          .collection('coupons')
          .get();

      List<Map<String, dynamic>> couponsList = [];
      if (couponsSnapshot.docs.isNotEmpty) {
        couponsList =
            couponsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      }

      setState(() {
        couponCodes = couponsList;
      });
    } catch (error) {
      print("Error fetching coupons: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('No data found.'));
          }

          if (snapshot.hasError) {
            return Center(child: Text('An error occurred.'));
          }

          Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
          List cartItems = userData['cart'] ?? [];

          if (cartItems.isEmpty) {
            return Center(child: Text('Cart is empty.'));
          }

          // // Calculate total bill
          // totalBill = 0;
          // for (var item in cartItems) {
          //   double subtotal = item['price'] * item['quantity'];
          //   totalBill += subtotal.toInt();
          // }
          totalBill = 0;
          for (var item in cartItems) {
            // Calculate the subtotal for each item (price * quantity)
            double subtotal = item['price'] * item['quantity'];

            // Convert subtotal to integer before adding to totalBill
            totalBill += subtotal.toInt(); // Use .toInt() to convert double to integer
          }


          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    var item = cartItems[index];
                    return ListTile(
                      leading: _buildPhoto(item['imageUrl']),
                      title: Text(item['name']),
                      subtitle: Text('₹ ${item['price'].toString()}'),
                      trailing: Text(item['quantity'].toString()),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (selectedCoupon.isNotEmpty)
                      Container(
                        color: darkMode ? Colors.black87 : Colors.white,
                        padding: EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Coupon Applied: $selectedCoupon',
                              style: TextStyle(fontSize: 16),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  selectedCoupon = '';
                                  discountPercentage = 0;
                                  maxDiscountRupees = 0;
                                });
                              },
                              child: Text(
                                'Remove',
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      'Available Coupons',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    _buildCouponsList(),
                    SizedBox(height: 10),
                    Text(
                      'Total: ₹$totalBill',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    if (selectedCoupon.isNotEmpty)
                      Text(
                        'Discounted Total: ₹${calculateDiscountedTotal()}',
                        style: TextStyle(fontSize: 18),
                      ),
                    SizedBox(height: 20),
                    Text(
                      'Select Table Number:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedTableNumber,
                      icon: Icon(Icons.arrow_drop_down),
                      iconSize: 24,
                      elevation: 16,
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedTableNumber = newValue;
                        });
                      },
                      items: tableOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option['number'],
                          child: Row(
                            children: [
                              Icon(option['icon']),
                              SizedBox(width: 10),
                              Text(option['number']),
                            ],
                          ),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: selectedTableNumber != null
                          ? () {
                        _showPaymentOptions(context);
                      }
                          : null,
                      child: Text('Place Order'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhoto(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    } else {
      return Icon(Icons.image, size: 50);
    }
  }

  Widget _buildCouponsList() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: couponCodes.length,
        itemBuilder: (context, index) {
          var coupon = couponCodes[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${coupon['code']}'),
                  Text('Discount: ${coupon['percentage']}%'),
                  Text('Max Discount: ₹${coupon['maxRupees']}'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedCoupon = coupon['code'];
                        discountPercentage = coupon['percentage'];
                        maxDiscountRupees = coupon['maxRupees'];
                      });
                    },
                    child: Text('Apply'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int calculateDiscountedTotal() {
    int discountedTotal = totalBill;

    if (discountPercentage > 0) {
      double discountAmount = (totalBill * discountPercentage / 100).round().toDouble();

      if (discountAmount > maxDiscountRupees) {
        discountAmount = maxDiscountRupees.toDouble();
      }

      discountedTotal = totalBill - discountAmount.toInt();
    }

    return discountedTotal;
  }

  void _showPaymentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Payment Option',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.credit_card),
                title: Text('Credit Card'),
                onTap: () {
                  _processPayment(context, 'Credit Card');
                },
              ),
              ListTile(
                leading: Icon(Icons.credit_card),
                title: Text('Debit Card'),
                onTap: () {
                  _processPayment(context, 'Debit Card');
                },
              ),
              ListTile(
                leading: Icon(Icons.account_balance_wallet),
                title: Text('UPI'),
                onTap: () {
                  _processPayment(context, 'UPI');
                },
              ),
              ListTile(
                leading: Icon(Icons.money),
                title: Text('Cash'),
                onTap: () {
                  _processPayment(context, 'Cash');
                },
              ),
              Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _processPayment(BuildContext context, String paymentMethod) async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Processing $paymentMethod payment...')),
    );

    DocumentSnapshot cartSnapshot =
    await _firestore.collection('users').doc(widget.userId).get();

    if (!cartSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cart is empty. No order placed.')),
      );
      return;
    }

    Map<String, dynamic> userData = cartSnapshot.data() as Map<String, dynamic>;
    List cartItems = userData['cart'] ?? [];
    int totalBill = calculateDiscountedTotal();

    Map<String, dynamic> orderData = {
      'userId': widget.userId,
      'shopId': widget.shopId,
      'items': cartItems,
      'totalBill': totalBill,
      'tableNumber': selectedTableNumber ?? 'Not selected',
      'paymentMethod': paymentMethod,
      'status': 'Order Accepted',
      'estimatedWaitTime': '14 minutes', // Example estimated time
      'createdAt': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('orders').add(orderData);
      await _firestore.collection('users').doc(widget.userId).update({'cart': []});

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed successfully.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyOrdersPage(userId: widget.userId)),
      );
    } catch (error) {
      print('Error placing order: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order. Please try again later.')),
      );
    }
  }
}
