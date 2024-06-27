import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import 'order_details_page.dart';

class MyOrdersPage extends StatefulWidget {
  final String userId;

  MyOrdersPage({required this.userId});

  @override
  _MyOrdersPageState createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Order Accepted':
        return Colors.green;
      case 'Preparing your order':
        return Colors.blue;
      case 'Ready':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  int _getStepIndex(String status) {
    switch (status) {
      case 'Order Accepted':
        return 0;
      case 'Preparing your order':
        return 1;
      case 'Ready':
        return 2;
      default:
        return 0; // Default to the first step if status is unknown
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Set<dynamic> favoriteOrders = Set<String>();

  @override
  void initState() {
    super.initState();
    _loadFavoriteOrders();
  }

  Future<void> _loadFavoriteOrders() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: widget.userId)
          .get();

      setState(() {
        favoriteOrders = querySnapshot.docs.map((doc) => doc['orderId']).toSet();
      });
    } catch (e) {
      print('Error loading favorite orders: $e');
    }
  }

  void _addToFavorites(DocumentSnapshot order) async {
    try {
      if (favoriteOrders.contains(order.id)) {
        // Remove from favorites
        setState(() {
          favoriteOrders.remove(order.id);
        });

        // Delete from Firestore
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: widget.userId)
            .where('orderId', isEqualTo: order.id)
            .get();
        querySnapshot.docs.forEach((doc) {
          doc.reference.delete();
        });
      } else {
        // Add to favorites
        setState(() {
          favoriteOrders.add(order.id);
        });

        // Save to Firestore
        await FirebaseFirestore.instance.collection('favorites').add({
          'userId': widget.userId,
          'orderId': order.id,
          'shopId': order['shopId'],
          'items': order['items'].map((item) => item['itemId']).toList(),
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error toggling favorite status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SMAAppBar(
        showBackArrow: Navigator.canPop(context),
        title: Text('My Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No orders found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var order = snapshot.data!.docs[index];
              String status = order['status']; // Assuming 'status' field exists in Firestore
              int currentStep = _getStepIndex(status);
              bool isFavorite = favoriteOrders.contains(order.id);

              return Dismissible(
                key: Key(order.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _addToFavorites(order);
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(
                    Icons.favorite,
                    color: Colors.white,
                  ),
                ),
                child: Card(
                  child: ExpansionTile(
                    title: Text(
                      'Order ID: ${order.id}',
                      style: TextStyle(color: _getStatusColor(status)),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Bill: ₹${order['totalBill']}'),
                        Text('Table Number: ${order['tableNumber']}'),
                        Text('Payment Method: ${order['paymentMethod']}'),
                      ],
                    ),
                    children: [
                      Stepper(
                        currentStep: currentStep,
                        controlsBuilder: (BuildContext context, ControlsDetails details) {
                          return Container(); // Hide the default buttons
                        },
                        steps: [
                          Step(
                            title: Text('Order Accepted'),
                            content: SizedBox.shrink(),
                            isActive: currentStep >= 0,
                          ),
                          Step(
                            title: Text('Preparing your order'),
                            content: SizedBox.shrink(),
                            isActive: currentStep >= 1,
                          ),
                          Step(
                            title: Text('Ready'),
                            content: SizedBox.shrink(),
                            isActive: currentStep >= 2,
                          ),
                        ],
                      ),
                    ],
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Iconsax.eye),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailsPage(order: order),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : null,
                          ),
                          onPressed: () {
                            _addToFavorites(order);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}



