import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dms/utils/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dms/features/social_media/screens/profile/profile_setting_page.dart';
import 'package:dms/features/social_media/screens/profile/user_profile_widget.dart';
import 'package:dms/utils/device/device_utility.dart';
import 'package:dms/utils/helpers/helper_fuctions.dart';
import 'package:dms/utils/theme/custom_theme/text_theme.dart';
import 'package:video_player/video_player.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../services/chat/chat_service.dart';
import '../../../../services/firestore.dart';
import '../../../../utils/constants/sizes.dart';
import '../home/favorite_orders.dart';
import '../home/models/shop_model.dart';
import '../home/my_orders_page.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  ProfilePage({
    Key? key,
    required this.uid,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FireStoreServices _fireStoreServices = FireStoreServices();
  late Future<DocumentSnapshot> _userDataFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  Map<String, dynamic>? userData;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  String? profilePicUrl;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fireStoreServices.getUserData(widget.uid);
    fetchUserData();
    _getCurrentUser();
    _fetchUserProfilePic();
    _loadFavoriteOrders();
  }

  void _getCurrentUser() {
    user = _auth.currentUser;
    if (user == null) {
      // Show a message or handle the scenario where user is null
      print("User is not authenticated.");
    } else {
      print("User is authenticated: ${user!.uid}");
    }
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(widget.uid).get();
      if (snapshot.exists) {
        setState(() {
          userData = snapshot.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Route _createRoute(UserProfile userProfile) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SettingsPage(
        userProfile: userProfile,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  File? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _submitProfilePicture();
    }
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      TaskSnapshot taskSnapshot = await _storage.ref(path).putFile(file);
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading file: $e");
      SMAHelperFunctions.showSnackBar(context, "Error uploading file: $e");
      return null;
    }
  }

  Future<void> _submitProfilePicture() async {
    setState(() {
      isLoading = true;
    });

    String? imageUrl;
    String userId = _auth.currentUser!.uid;
    if (_selectedImage != null) {
      imageUrl = await _uploadFile(
        _selectedImage!,
        'profile_photo/$userId/images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    }

    if (imageUrl != null) {
      await _firestore.collection('profile_pics').doc(userId).set({
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'userId': userId,
      });

      await _firestore.collection('users').doc(userId).update({
        'profilePic': imageUrl,
      });

      setState(() {
        userData!['profilePic'] = imageUrl;
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchUserProfilePic() async {
    String userId = _auth.currentUser!.uid;
    QuerySnapshot querySnapshot = await _firestore
        .collection('profile_pics')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        profilePicUrl = querySnapshot.docs.first['imageUrl'];
      });
    }
  }

  ImageProvider _getImageProvider() {
    if (profilePicUrl != null && profilePicUrl!.isNotEmpty) {
      return NetworkImage(profilePicUrl!);
    } else {
      return AssetImage('assets/user.png');
    }
  }

  Set<String> favoriteOrders = Set<String>();


  void _loadFavoriteOrders() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .get();

      setState(() {
        favoriteOrders = snapshot.docs.map((doc) => doc['orderId'] as String).toSet();
      });
    } catch (e) {
      print('Error loading favorite orders: $e');
    }
  }

  void _navigateToFavoritesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FavoritesPage(favoriteOrders: favoriteOrders),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool dark = SMAHelperFunctions.isDarkMode(context);

    Widget _buildTile(
        {required String title,
        required IconData icon,
        required Function() onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: dark ? SMAColors.darkContainer : SMAColors.lightContainer,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              Icon(
                icon,
              ),
              SizedBox(width: 16.0),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }



    return Scaffold(
        appBar: SMAAppBar(
          showBackArrow: _auth.currentUser!.uid == widget.uid ? false : true,
          title: Text("Profile",
              style: dark
                  ? SMATextTheme.darkTextTheme.headlineMedium
                  : SMATextTheme.lightTextTheme.headlineMedium),
          actions: [
            FutureBuilder<DocumentSnapshot>(
              future: _userDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: SizedBox.shrink());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("User data not found"));
                } else {
                  var userData = snapshot.data!.data() as Map<String, dynamic>;

                  UserProfile userProfile = UserProfile(
                    firstName: userData['firstName'] ?? '',
                    lastName: userData['lastName'] ?? '',
                    phoneNumber: userData['phoneNumber'] ?? 'Phone Number',
                    uid: userData['uid'] ?? _auth.currentUser!.uid,
                    profilePic: userData['profilePic'] ?? 'Profile Picture',
                    email: userData['email'] ?? "Email",
                  );

                  return userProfile.uid == _auth.currentUser!.uid
                      ? IconButton(
                          onPressed: () {
                            Navigator.of(context)
                                .push(_createRoute(userProfile));
                          },
                          icon: const Icon(Icons.settings),
                        )
                      : SizedBox.shrink();
                }
              },
            ),
          ],
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("User data not found"));
            } else {
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              UserProfile userProfile = UserProfile(
                firstName: userData['firstName'] ?? '',
                lastName: userData['lastName'] ?? '',
                phoneNumber: userData['phoneNumber'] ?? 'Phone Number',
                uid: userData['uid'] ?? _auth.currentUser!.uid,
                profilePic: userData['profilePic'] ?? 'Profile Picture',
                email: userData['email'] ?? "",
              );
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(SMASizes.md),
                  child: Column(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        margin: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: dark
                                ? SMAColors.darkContainer
                                : SMAColors.lightContainer),
                        child: Padding(
                          padding: const EdgeInsets.all(SMASizes.defaultSpace),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Personal Information",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall),
                                ],
                              ),
                              const SizedBox(height: SMASizes.spaceBtwSections),
                              Center(
                                child: CircleAvatar(
                                  //backgroundColor: dark? SMAColors.darkContainer : SMAColors.lightContainer,
                                  radius: 50,
                                  backgroundImage:
                                      userProfile.profilePic.isNotEmpty
                                          ? NetworkImage(userProfile.profilePic)
                                          : AssetImage('assets/user.png')
                                              as ImageProvider,
                                ),
                              ),
                              const SizedBox(height: SMASizes.spaceBtwSections),
                              Expanded(
                                child: Text(
                                  'First Name: ${userProfile.firstName}',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Last Name: ${userProfile.lastName}',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Phone Number: ${userProfile.phoneNumber}',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Email Address: ${userProfile.email}',
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      _buildTile(
                        title: 'Your orders',
                        icon: Iconsax.shopping_bag,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyOrdersPage(
                                  userId: _auth.currentUser!.uid,
                                ),
                              ));
                        },
                      ),
                      SizedBox(height: 16.0),
                      _buildTile(
                        title: 'Favourite orders',
                        icon: Iconsax.heart,
                        onTap: () {
                          _navigateToFavoritesPage();
                        },
                      ),
                      SizedBox(height: 16.0),
                      _buildTile(
                        title: 'Payment setting',
                        icon: Iconsax.card,
                        onTap: () {
                          SMAHelperFunctions.showSnackBar(context, "Under Development");
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ));
  }
}
