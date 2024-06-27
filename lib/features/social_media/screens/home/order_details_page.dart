import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import 'cart_page.dart';

class OrderDetailsPage extends StatelessWidget {
  final DocumentSnapshot order;

  OrderDetailsPage({required this.order});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    bool isOrderServed = order['status'] == 'Ready';
    List<dynamic> items = order['items'];

    return Scaffold(
      appBar: SMAAppBar(
        title: Text('Order Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order details section
            Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID: ${order.id}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('Ordered at: ${_formatTimestamp(order['createdAt'])}'),
                    Text('Total Bill: ₹${order['totalBill']}'),
                    Text('Table Number: ${order['tableNumber']}'),
                    Text('Payment Method: ${order['paymentMethod']}'),
                  ],
                ),
              ),
            ),

            // Divider between order details and status specific sections
            Divider(height: 20, thickness: 2),

            // Display all items and quantities
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                var item = items[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text('Quantity: ${item['quantity']}'),
                );
              },
            ),

            // Divider between items and status specific sections
            Divider(height: 20, thickness: 2),

            // Status specific section
            isOrderServed
                ? _buildCompletedOrderSection(context, items)
            : SizedBox.shrink(),
              //  : _buildPreparingOrderSection(),

            // Additional actions or buttons as needed
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showFeedbackDialog(context, items);
              },
              child: Text('Give Feedback'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreparingOrderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Order Status: ${order['status']}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text('We are currently working on your order.'),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // Implement chat functionality with restaurant
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat),
              SizedBox(width: 10),
              Text('Chat with Restaurant'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedOrderSection(BuildContext context, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Order Status: Completed',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text('Your order has been completed and served.'),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            _showFeedbackDialog(context, items);
          },
          child: Text('Give Feedback'),
        ),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context, List<dynamic> items) {
    String feedbackText = '';
    double rating = 0.0;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Provide Feedback',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(labelText: 'Your Feedback'),
                    onChanged: (value) {
                      feedbackText = value;
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Rate your experience',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Slider(
                    value: rating,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    onChanged: (newRating) {
                      setState(() {
                        rating = newRating;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        child: Text('Submit'),
                        onPressed: () async {
                          Navigator.of(context).pop(); // Close the bottom sheet

                          // Prepare feedback data
                          Map<String, dynamic> feedbackData = {
                            'customerId': _auth.currentUser!.uid,
                            'shopId': order['shopId'],
                            'items': items.map((item) => item['itemId']).toList(),
                            'feedbackText': feedbackText,
                            'rating': rating,
                            'createdAt': Timestamp.now(),
                            'orderId': order.id,
                          };

                          try {
                            // Add feedback to Firestore
                            await _firestore.collection('feedback').add(feedbackData);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Feedback submitted successfully')),
                            );
                          } catch (e) {
                            // Show error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to submit feedback: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReorderConfirmationDialog(BuildContext context, String userId, List<dynamic> items) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Reorder'),
          content: Text('Are you sure you want to reorder these items?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _reorderItems(context, userId, items); // Call the reorder function
              },
            ),
          ],
        );
      },
    );
  }

  void _reorderItems(BuildContext context, String userId, List<dynamic> items) async {
    try {
      DocumentReference userDoc = _firestore.collection('users').doc(userId);
      DocumentSnapshot userSnapshot = await userDoc.get();

      // Get the current cart items
      Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
      List cartItems = userData['cart'] ?? [];

      // Iterate through the items and update the quantities
      for (var newItem in items) {
        bool itemExists = false;
        for (var cartItem in cartItems) {
          if (cartItem['itemId'] == newItem['itemId']) {
            cartItem['quantity'] += newItem['quantity'];
            itemExists = true;
            break;
          }
        }
        if (!itemExists) {
          cartItems.add(newItem);
        }
      }

      // Update the user's cart in Firestore
      await userDoc.update({'cart': cartItems});

      // Navigate to the cart page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartPage(userId: _auth.currentUser!.uid, shopId: order['shopId'])),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding items to cart: $e')),
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}
