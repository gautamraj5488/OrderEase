import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'menu_screen/menu_screen.dart';
import 'models/shop_model.dart';

class ShopScreen extends StatelessWidget {
  final List<Shop> shops;
  ShopScreen({Key? key, required this.shops}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: shops.length,
        itemBuilder: (context, index) {
          return ShopWidget(shop: shops[index]);
        },
      ),
    );
  }
}

class ShopWidget extends StatelessWidget {
  final Shop shop;

  ShopWidget({required this.shop});

  @override
  Widget build(BuildContext context) {
    bool dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MenuScreen(shop: shop),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.all(10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BuildPhotoWidget(imageUrl: shop.imageUrl),
              SizedBox(height: 10),
              Text(
                shop.shopName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 5),
                  Text(
                    shop.ratings.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      color: dark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BuildPhotoWidget extends StatelessWidget {
  final String? imageUrl;

  const BuildPhotoWidget({Key? key, this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildPhoto();
  }

  Widget _buildPhoto() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) {
            if (kDebugMode) {
              print('Error loading image: $error');
            }
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 50),
                SizedBox(height: 10),
                Text(
                  'Failed to load image.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            );
          },
          fit: BoxFit.cover,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
