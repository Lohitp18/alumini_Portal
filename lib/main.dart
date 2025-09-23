import 'package:flutter/material.dart';
import 'pages/signin.dart';
import 'pages/signup.dart';
import 'main_app_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alumni Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const SignInPage(),
        '/home': (context) => const MainAppPage(),
        '/signup': (context) => const SignUpPage(),
      },
    );
  }
}
