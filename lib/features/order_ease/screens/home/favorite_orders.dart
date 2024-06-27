import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import 'order_details_page.dart';

class FavoritesPage extends StatelessWidget {
  final Set<String> favoriteOrders;

  FavoritesPage({required this.favoriteOrders});

  FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SMAAppBar(
        title: Text('Favorite Orders'),
      ),
      body: favoriteOrders.isEmpty
          ? Center(
        child: Text('No favorite orders found.'),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: _auth.currentUser!.uid)
            .where('orderId', whereIn: favoriteOrders.toList())
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
            return Center(child: Text('No favorite orders found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var favorite = snapshot.data!.docs[index];
              String orderId = favorite['orderId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
                builder: (context, orderSnapshot) {
                  if (orderSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (orderSnapshot.hasError) {
                    print('Error loading order: ${orderSnapshot.error}');
                    return Center(child: Text('Error loading order: ${orderSnapshot.error}'));
                  }

                  if (!orderSnapshot.hasData || !orderSnapshot.data!.exists) {
                    return Center(child: Text('Order data not found.'));
                  }

                  var order = orderSnapshot.data!;
                  String status = order['status'];
                  int currentStep = _getStepIndex(status);

                  return Card(
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
                      trailing: IconButton(
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
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
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
        return 0;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Order Accepted':
        return Colors.blue;
      case 'Preparing your order':
        return Colors.orange;
      case 'Ready':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}