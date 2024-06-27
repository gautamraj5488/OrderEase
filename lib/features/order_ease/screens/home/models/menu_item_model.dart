import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String name;
  final String imageUrl;
  final double price;
  final String description;
  final String itemId;
  final String category;

  MenuItem(
      {required this.itemId,
      required this.name,
      required this.imageUrl,
      required this.price,
      required this.description,
        required this.category,
      });

  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      name: data['itemName'] ?? '',
      imageUrl: data['itemImageUrl'] ?? '',
      price: data['price'] != null ? (data['price'] as num).toDouble() : 0.0,
      description: data['description'],
      itemId: data['itemId']??"",
      category: data['category'] ?? 'Uncategorized',
    );
  }
}
