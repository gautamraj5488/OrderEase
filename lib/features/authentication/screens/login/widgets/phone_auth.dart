import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../common/styles/spacing_style.dart';
import '../../../../../common/widgets.login_signup/form_divider.dart';
import '../../../../../common/widgets.login_signup/social_button.dart';
import '../../../../../navigation_menu.dart';
import '../../../../../services/firestore.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_fuctions.dart';
import '../helper/email_helper.dart';
import 'header.dart';

class PhoneAuthScreen extends StatefulWidget {
  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FireStoreServices _fireStoreServices = FireStoreServices();
  String _verificationId = '';
  bool _isOtpSent = false;
  final FocusNode _pinPutFocusNode = FocusNode();

  // @override
  // void initState() {
  //   super.initState();
  //   FirebaseAppCheck.instance.activate();
  // }

  void _sendOtp() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+91${_phoneController.text}",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          SMAHelperFunctions.showSnackBar(context, 'The provided phone number is not valid.');
          print('The provided phone number is not valid.');
        } else {
          SMAHelperFunctions.showSnackBar(context,'Phone number verification failed: ${e.message}');
          print('Phone number verification failed: ${e.message}');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isOtpSent = true;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
        });
      },
    );
  }


  void _verifyOtp() async {
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: _otpController.text,
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      User? user = userCredential.user;
      if (user != null) {
        final email = emailController.text;
        await _fireStoreServices.createUserInFirestore(user,email);
        final firstName = user.displayName?.split(' ')[0] ?? 'User';
        final lastName = user.displayName?.split(' ').sublist(1).join(' ') ?? '';
        await EmailHelper.sendWelcomeEmail(email, "$firstName $lastName");
      }

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Navigation()));
    } catch (e) {
      SMAHelperFunctions.showSnackBar(context, 'Failed to sign in: $e');
      print('Failed to sign in: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    final dark = SMAHelperFunctions.isDarkMode(context);

    BoxDecoration pinPutDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10.0),
      border: Border.all(color: Colors.grey),
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: SMASpacingStyle.paddingWithAppBarHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SMALoginHeader(dark: dark),
              SizedBox(
                height: SMASizes.spaceBtwSections,
              ),
              if (!_isOtpSent) ...[
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefix: Text('+91 '),
                    prefixStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(
                  height: SMASizes.spaceBtwInputFields,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Iconsax.direct_right),
                      labelText: SMATexts.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: SMASizes.spaceBtwInputFields),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sendOtp,
                    child: Text('Send OTP'),
                  ),
                ),

                SizedBox(
                  height: SMASizes.spaceBtwSections,
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(labelText: 'OTP'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(
                  height: SMASizes.spaceBtwSections,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifyOtp,
                    child: Text('Verify OTP'),
                  ),
                ),
                SizedBox(
                  height: SMASizes.spaceBtwSections,
                ),
              ],
              SMAFormDivider(dark: dark,text: SMATexts.orSignInWith,),
              SizedBox(
                height: SMASizes.spaceBtwSections,
              ),
              SMASocialButton(),
            ],
          ),
        ),
      ),
    );
  }
}
