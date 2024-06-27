import 'package:dms/features/authentication/screens/login/widgets/phone_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../navigation_menu.dart';

class AuthPage extends StatelessWidget {
  AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                children: [
                  Image.asset("assets/gifs/error.gif"),
                  Text("Error: ${snapshot.error}")
                ],
              ),
            );
            //return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            // User is logged in, now check for user data in Firestore
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (userSnapshot.hasError) {
                  return Center(child: Text("Error: ${userSnapshot.error}"));
                } else if (!userSnapshot.hasData || !userSnapshot.data!.exists) {

                  // No user data found in Firestore, navigate to PhoneAuthScreen
                  return PhoneAuthScreen();
                } else {
                  // User data found, navigate to Navigation screen
                  return Navigation();
                }
              },
            );
          } else {
            // No user is logged in
            return PhoneAuthScreen();
          }
        },
      ),
    );
  }
}
