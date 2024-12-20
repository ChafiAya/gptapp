import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'views/home_page.dart';
import 'views/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterGPT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(
        useMaterial3: true,
      ),
      home: AuthCheck(),
    );
  }
}

// Widget pour vérifier l'authentification
class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Vérifie si un utilisateur est déjà connecté
    User? user = FirebaseAuth.instance.currentUser;

    // Redirige vers HomePage si connecté, sinon LoginPage
    if (user != null) {
      return const HomePage();
    } else {
      return LoginPage();
    }
  }
}
