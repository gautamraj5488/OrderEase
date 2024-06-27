import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dms/utils/helpers/helper_fuctions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../services/firestore.dart';
import '../cart_page.dart';
import '../models/menu_item_model.dart';
import '../models/shop_model.dart';

class MenuScreen extends StatefulWidget {
  final Shop shop;
  MenuScreen({required this.shop});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  List<MenuItem> menuItems = [];
  List<MenuItem> filteredItems = [];
  String selectedCategory = 'All';

  List<Map<String, dynamic>> coupons = [];

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
    print('length of coupons are ${coupons.length}');
  }

  Future<void> _fetchCoupons() async {
    try {
      // Query the subcollection 'coupons' inside the shop document
      QuerySnapshot couponsSnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shop.shopId)
          .collection('coupons')
          .get();

      // Initialize list to store coupons
      List<Map<String, dynamic>> couponsList = [];

      // Process snapshot if data exists
      if (couponsSnapshot.docs.isNotEmpty) {
        couponsList = couponsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      }

      // Update state with fetched coupon codes
      setState(() {
        coupons = couponsList;
      });
    } catch (error) {
      print("Error fetching coupons: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SMAAppBar(
        title: Text(widget.shop.shopName),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage(userId: _auth.currentUser!.uid, shopId: widget.shop.shopId)),
              );
            },
            icon: Icon(Iconsax.shopping_cart),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          coupons.isEmpty
              ? Center(child: CircularProgressIndicator())
              : CarouselSlider(
            options: CarouselOptions(
              height: 300.0,
              autoPlay: true,
              enlargeCenterPage: true,
            ),
            items: coupons.map((coupon) {
              return Builder(
                builder: (BuildContext context) {
                  return Card(
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/light.png",
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Code: ${coupon['code']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Discount: ${coupon['percentage']}%', style: TextStyle(fontSize: 16)),
                              Text('Max Discount: ₹${coupon['maxRupees']}', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
          // CarouselSlider(
          //   options: CarouselOptions(
          //     height: 200, // Adjust the height of the carousel slider
          //     enlargeCenterPage: true,
          //     enableInfiniteScroll: true,
          //     autoPlay: true,
          //     autoPlayInterval: Duration(seconds: 3), // Adjust the auto-play interval
          //     autoPlayAnimationDuration: Duration(milliseconds: 800), // Animation duration
          //     scrollDirection: Axis.horizontal,
          //   ),
          //   items: _buildCarouselImages(), // Method to build carousel items/images
          // ),
          SizedBox(height: 10), // Adjust spacing between carousel and category tabs
          _buildSearchBar(), // Method to build search bar
          SizedBox(height: 10), // Adjust spacing between search bar and category tabs
          _buildCategoryTabs(), // Method to build category selection tabs/buttons
          Expanded(
            child: _buildMenuList(), // Method to build the list of menu items based on selected category and search query
          ),
        ],
      ),
    );
  }

  // List<String> placeholderUrls = [
  //   'https://via.placeholder.com/600x400',
  //   'https://via.placeholder.com/600x400',
  //   'https://via.placeholder.com/600x400',
  //   // Add more placeholder URLs as needed
  // ];
  //
  // List<Widget> _buildCarouselImages() {
  //   return placeholderUrls.map((url) {
  //     return Image.network(url, fit: BoxFit.cover);
  //   }).toList();
  // }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (query) {
          _performSearch(query);
        },
        decoration: InputDecoration(
          hintText: 'Search...',
          suffixIcon: IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // You can optionally keep this onPressed handler for search button press
              _performSearch(_searchController.text);
            },
          ),
        ),
      ),
    );
  }

  void _performSearch(String query) {
    setState(() {
      // Convert query to lowercase for case-insensitive search
      String lowercaseQuery = query.toLowerCase();

      // Filter menu items based on both category and search query
      filteredItems = menuItems.where((item) {
        bool categoryMatches = item.category == selectedCategory || selectedCategory == 'All';
        bool nameMatches = item.name.toLowerCase().contains(lowercaseQuery);
        return categoryMatches && nameMatches;
      }).toList();
    });
  }



  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          _buildCategoryButton('All'),
          _buildCategoryButton('Fast Food'),
          _buildCategoryButton('Veg'),
          _buildCategoryButton('Non Veg'),
          _buildCategoryButton('Meal'),
          _buildCategoryButton('Starter'),
          _buildCategoryButton('Healthy'),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    bool dark = SMAHelperFunctions.isDarkMode(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedCategory = category;
            _performSearch(_searchController.text); // Refresh filtered items on category change
          });
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: dark ? Colors.white : Colors.black, backgroundColor: dark
            ? selectedCategory == category ? Colors.blue : Colors.grey[700]
            : selectedCategory == category ? Colors.blue : Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Adjust the border radius as needed
          ),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Adjust padding for button size
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 16, // Adjust font size as needed
            fontWeight: FontWeight.bold, // Adjust font weight as needed
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shop.shopId)
          .collection('items')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error fetching menu items'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No menu items available'));
        } else {
          // Update menuItems based on snapshot data
          menuItems = snapshot.data!.docs.map((doc) => MenuItem.fromFirestore(doc)).toList();

          // Filter menu items based on selected category and search query
          List<MenuItem> filteredItems = menuItems.where((item) =>
          (item.category == selectedCategory || selectedCategory == 'All')
          ).toList();

          // Perform search filtering if there is a search query
          if (_searchController.text.isNotEmpty) {
            String query = _searchController.text.toLowerCase();
            filteredItems = filteredItems.where((item) =>
                item.name.toLowerCase().contains(query)
            ).toList();
          }

          return filteredItems.isEmpty
              ? Center(
            child: Text(
              'No items available.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          )
              : ListView.builder(
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              return MenuItemWidget(menuItem: filteredItems[index], userId: _auth.currentUser!.uid);
            },
          );

        }
      },
    );
  }

}

class MenuItemWidget extends StatefulWidget {
  final MenuItem menuItem;
  final String userId;

  MenuItemWidget({required this.menuItem, required this.userId});

  @override
  _MenuItemWidgetState createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<MenuItemWidget> {
  bool isExpanded = false;
  int quantity = 0;
  final FireStoreServices _firestoreService = FireStoreServices();

  @override
  void initState() {
    super.initState();
    _loadInitialQuantity();
  }

  Future<void> _loadInitialQuantity() async {
    try {
      DocumentSnapshot userSnapshot = await _firestoreService.getCartItems(widget.userId).first;
      Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
      List cartItems = userData['cart'] ?? [];

      for (var item in cartItems) {
        if (item['itemId'] == widget.menuItem.itemId) {
          setState(() {
            quantity = item['quantity'];
          });
          break;
        }
      }
    } catch (e) {
      print("Error loading initial quantity: $e");
    }
  }

  void _incrementQuantity() async {
    setState(() {
      quantity++;
    });
    try {
      await _firestoreService.updateItemInCart(widget.userId, widget.menuItem.itemId, quantity, widget.menuItem.name, widget.menuItem.price, widget.menuItem.imageUrl);
      print("Added to cart");
    } catch (e) {
      print("Error incrementing quantity: $e");
    }
  }

  void _decrementQuantity() async {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
      try {
        await _firestoreService.updateItemInCart(widget.userId, widget.menuItem.itemId, quantity, widget.menuItem.name, widget.menuItem.price, widget.menuItem.imageUrl);
      } catch (e) {
        print("Error decrementing quantity: $e");
      }
    } else {
      setState(() {
        quantity = 0;
      });
      try {
        await _firestoreService.removeItemFromCart(widget.userId, widget.menuItem.itemId);
      } catch (e) {
        print("Error removing item from cart: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              ListTile(
                leading: !isExpanded
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: BuildPhotoWidget(
                    imageUrl: widget.menuItem.imageUrl,
                    isExpanded: isExpanded,
                  ),
                )
                    : null,
                title: Text(
                  widget.menuItem.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '₹ ${widget.menuItem.price.toString()}',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                trailing: quantity == 0
                    ? IconButton(
                    onPressed: _incrementQuantity,
                    icon: Icon(Iconsax.shopping_cart))
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        quantity > 1 ? Iconsax.minus : Iconsax.trash,
                      ),
                      onPressed: _decrementQuantity,
                    ),
                    Text(
                      quantity.toString(),
                      style: TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: Icon(Iconsax.add),
                      onPressed: _incrementQuantity,
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
              ),
              AnimatedCrossFade(
                firstChild: SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: BuildPhotoWidget(
                          imageUrl: widget.menuItem.imageUrl,
                          isExpanded: isExpanded,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        widget.menuItem.description,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
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
  final bool isExpanded;

  const BuildPhotoWidget({Key? key, this.imageUrl, required this.isExpanded}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildPhoto();
  }

  Widget _buildPhoto() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.image, color: Colors.red),
            ],
          );
        },
        fit: BoxFit.cover,
        width: isExpanded ? double.infinity : 60.0,
        height: isExpanded ? 200.0 : 60.0,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}


