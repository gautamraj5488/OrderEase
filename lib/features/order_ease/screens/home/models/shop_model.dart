import 'package:cloud_firestore/cloud_firestore.dart';

class Shop {
  final String shopId;
  final String shopName;
  final String imageUrl;
  final String videoUrl;
  final Timestamp createdAt;
  final String ratings;
  final int numberOfTables;

  Shop({
    required this.shopId,
    required this.shopName,
    required this.ratings,
    required this.imageUrl,
    required this.videoUrl,
    required this.createdAt,
    required this.numberOfTables,
  });

  factory Shop.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;

    return Shop(
      imageUrl: data['imageUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      shopId: data['shopId'],
      shopName: data['shopName'],
      ratings: data["avgRating"] ?? 0,
      numberOfTables: data['numberOfTables'] ?? 0,
    );
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      imageUrl: json['imageUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      createdAt: Timestamp.fromMillisecondsSinceEpoch(json['createdAt']),
      shopId: json['shopId'],
      shopName: json['shopName'],
      ratings: json['avgRating'],
      numberOfTables: json['numberOfTables'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'shopId': shopId,
      'shopName': shopName,
      'ratings': ratings,
      'numberOfTables': numberOfTables,
    };
  }
}
