import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dms/services/firestore.dart';
import 'package:dms/utils/constants/colors.dart';
import 'package:dms/utils/helpers/helper_fuctions.dart';
import 'common/widgets/appbar/appbar.dart';
import 'features/authentication/screens/login/helper/email_helper.dart';
import 'features/social_media/screens/home/create_post.dart';
import 'features/social_media/screens/home/home.dart';
import 'features/social_media/screens/home/my_orders_page.dart';
import 'features/social_media/screens/profile/profile_page.dart';
import 'features/social_media/screens/search/search_screen.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;

  final FireStoreServices _firestoreServices = FireStoreServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;


  @override
  void initState() {
    super.initState();
  }



  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final dark = SMAHelperFunctions.isDarkMode(context);

    final List<Widget> _pages = [
      HomeScreen(),
      // SearchScreen(),
      // Scaffold(),
      ProfilePage(uid: _auth.currentUser!.uid,),
    ];

    return Scaffold(

        bottomNavigationBar: NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: dark ? SMAColors.black : Colors.white,
          indicatorColor: dark
              ? SMAColors.white.withOpacity(0.1)
              : SMAColors.black.withOpacity(0.1),
          destinations: [
            NavigationDestination(icon: Icon(Iconsax.home), label: 'Home'),
            // NavigationDestination(
            //     icon: Icon(Iconsax.search_normal), label: 'Search'),
            // // NavigationDestination(icon: Icon(Iconsax.message), label: 'Chat'),
            // Stack(
            //
            //   children: [
            //     NavigationDestination(icon: Icon(Iconsax.message), label: 'Chat'),
            //     Positioned(
            //       top: 7,
            //       right: 33,
            //       child: Container(
            //       padding: EdgeInsets.all(5),
            //       decoration: BoxDecoration(
            //           color: Colors.red,
            //           shape: BoxShape.circle,
            //           border: Border.all(width: 1,color: dark? SMAColors.white : SMAColors.black)
            //       ),
            //       child: Text('',style: TextStyle(fontSize: 10,fontWeight: FontWeight.w600),),
            //     ),),
            //
            //   ],
            // ),
            NavigationDestination(icon: Icon(Iconsax.user), label: 'Profile'),
          ],
        ),
        body: _pages[_selectedIndex]);
  }
}


