import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dms/features/authentication/screens/login/login.dart';
import 'package:dms/utils/helpers/helper_fuctions.dart';

import '../../../../services/firestore.dart';
import '../../../../utils/constants/colors.dart';
import 'activity.dart';
import 'create_post.dart';
import 'shop_screen.dart';
import 'models/shop_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final FireStoreServices _fireStoreServices = FireStoreServices();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Future<DocumentSnapshot> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fireStoreServices.getUserData(_auth.currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: YourAppBar(),
        body: FutureBuilder<QuerySnapshot>(
          future: _firestore.collection('shops').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Image.asset("assets/gifs/loading.gif"));
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error fetching data'),
              );
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text('No shops available'),
              );
            } else {
              List<Shop> shops = snapshot.data!.docs.map((doc) => Shop.fromFirestore(doc)).toList();
              return ShopScreen(shops: shops);
            }
          },
        ));
  }
}

class YourAppBar extends StatefulWidget implements PreferredSizeWidget {
  const YourAppBar({super.key});
  @override
  State<YourAppBar> createState() => _YourAppBarState();

  @override
  Size get preferredSize => AppBar().preferredSize;
}

class _YourAppBarState extends State<YourAppBar> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;


  int requestToConfirmLength = 0;

  @override
  void initState() {
    super.initState();
    _getRequestToConfirmLength();
  }

  Future<void> _getRequestToConfirmLength() async {
    final String? currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      if (kDebugMode) {
        print('Error: No current user logged in');
      }
      return;
    }

    try {
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists) {
        final Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?; // Cast to Map<String, dynamic>
        if (userData != null) {
          final List<dynamic>? requestToConfirm = userData['requestToConfirm'] as List<dynamic>?; // Access the 'requestToConfirm' key
          setState(() {
            requestToConfirmLength = requestToConfirm?.length ?? 0;
          });
        } else {
          print('User data is null');
        }
      } else {
        print('User document not found');
      }

    } catch (e) {
      print('Error fetching requestToConfirm list: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    bool dark = SMAHelperFunctions.isDarkMode(context);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        User? currentUser = snapshot.data;

        if (currentUser == null) {
          return AppBar(
            title: Text('User not found'),
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(currentUser.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return AppBar(
                title: Text('Loading...'),
              );
            } else if (userSnapshot.hasError) {
              return AppBar(
                title: Text('Error'),
              );
            } else if (!userSnapshot.hasData || userSnapshot.data == null) {
              return AppBar(
                title: Text('User not found'),
              );
            } else {


              final data = userSnapshot.data?.data();
              if (data is! Map<String, dynamic>) {
                return AppBar(
                  title: Text('User data is not valid'),
                );
              }

              Map<String, dynamic> userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              String firstName = userData['firstName'] ?? 'User';
              String name = '$firstName ${userData['lastName'] ?? 'User'}';

              return AppBar(
                title: Text('Welcome, $firstName'),
              );
            }
          },
        );
      },
    );
  }
}
