import 'package:flutter/material.dart';
import 'package:otpand/pages/homepage.dart';

void main() {
  runApp(OTPApp());
}

class OTPApp extends StatelessWidget {
  const OTPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OtpAnd',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}
