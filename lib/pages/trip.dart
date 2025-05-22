import 'package:flutter/material.dart';
import 'package:otpand/objects/trip.dart';

class TripPage extends StatelessWidget {
  final Trip trip;

  const TripPage({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip')),
      body: const Center(
        child: Text('Coming soon', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
