import 'package:flutter/material.dart';
import 'package:koperasiapp/screen/home_page.dart';
import 'package:koperasiapp/screen/login_page.dart';
import 'package:koperasiapp/screen/register_terms_page.dart';
import 'constants.dart';
import 'home.dart';
// import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // return const MaterialApp(
    //   title: 'Flutter Demo',
    //   // home: Home(),
    //   home: LoginPage(),
    //   debugShowCheckedModeBanner: false,
    // );
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeStyle.lightTheme(context),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        // '/': (context) => const SignupScreen(),
      },
    );
  }
}
