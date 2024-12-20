import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_page.dart'; // Make sure this page exists
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Import Crashlytics

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  Future<void> _signUp() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      String? uid = userCredential.user?.uid;

      // Store user data in Firestore
      await _firestore.collection('users').doc(uid).set({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'uid': uid,
      });

      // Navigate to the login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e, stackTrace) {
      print('Error in sign-up: ${e.toString()}'); // Added print statement
      FirebaseCrashlytics.instance.recordError(e, stackTrace); // Log error to Crashlytics
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Sign up using Google
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign-In canceled by user'); // Added print statement
        return; // User canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Google credentials
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // If the user is new, store additional user info in Firestore
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'firstName': googleUser.displayName?.split(' ').first ?? '',
          'lastName': googleUser.displayName?.split(' ').last ?? '',
          'email': googleUser.email,
          'uid': userCredential.user?.uid,
        });
      }

      // Navigate to the login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e, stackTrace) {
      print('Error in Google Sign-In: ${e.toString()}'); // Added print statement
      FirebaseCrashlytics.instance.recordError(e, stackTrace); // Log error to Crashlytics
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(  // Added back button icon
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);  // Navigate back to the previous screen
          },
        ),
      ),
      body: Center(  // Center all content in the body
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(  // Ensures all content is scrollable
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Vertically center the content
              crossAxisAlignment: CrossAxisAlignment.center, // Center items horizontally
              children: [
                const Icon(
                  Icons.account_circle,  // You can replace this with your own icon if necessary
                  size: 100,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                // First Name TextField
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 10),
                // Last Name TextField
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.person_add),
                  ),
                ),
                const SizedBox(height: 10),
                // Email TextField
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 10),
                // Password TextField
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                // Sign Up Button with Background Color
                ElevatedButton.icon(
                  onPressed: _signUp,
                  icon: const Icon(Icons.app_registration),
                  label: const Text('Sign Up'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(230, 50),   // Full width button
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor: Colors.blue,  // Background color for the button
                  ),
                ),
                const SizedBox(height: 20),
                // Google Sign Up Button with Background Color
                ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Sign Up with Google'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(230, 50),   // Full width button
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor: Colors.red,  // Background color for the button
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
