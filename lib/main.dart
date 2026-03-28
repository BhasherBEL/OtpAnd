import 'dart:async';

import 'package:flutter/material.dart';
import 'package:otpand/api/gtfs_maas.dart';
import 'package:otpand/db/crud/agencies.dart';
import 'package:otpand/db/crud/favourites.dart';
import 'package:otpand/db/crud/plans.dart';
import 'package:otpand/db/crud/profiles.dart';
import 'package:otpand/db/crud/search_history.dart';
import 'package:otpand/db/crud/stops.dart';
import 'package:otpand/objects/config.dart';
import 'package:otpand/pages/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Config().init();

  // Ensure a default profile exists before the UI renders.
  await ProfileDao.ensureBlankProfile();

  // Warm up in-memory caches from the local DB (non-blocking).
  unawaited(StopDao().loadAll());
  unawaited(FavouriteDao().loadAll());
  unawaited(SearchHistoryDao().loadAll());
  unawaited(AgencyDao().loadAll());
  unawaited(PlanDao().loadAll());

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
    // Sync GTFS catalogue data from maas-rs (stops, routes, agencies).
    // Runs in the background; at most once every 23 hours.
    unawaited(checkAndSyncMaasGtfsData());
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
