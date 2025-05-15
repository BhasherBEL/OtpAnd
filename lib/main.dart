import 'package:flutter/material.dart';
import 'package:otpand/api/gtfs.dart';
import 'package:otpand/pages/homepage.dart';

void main() {
  runApp(OTPApp());
}

class OTPApp extends StatefulWidget {
  const OTPApp({super.key});

  @override
  State<OTPApp> createState() => _OTPAppState();
}

class _OTPAppState extends State<OTPApp> {
  @override
  void initState() {
    super.initState();
    checkAndSyncGtfsData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OtpAnd',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
