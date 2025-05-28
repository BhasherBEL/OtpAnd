import 'package:flutter/material.dart';
import 'package:otpand/objects/route.dart';
import 'package:otpand/objects/stop.dart';

class TransitItem extends StatelessWidget {
  final Stop stop;
  final VoidCallback? onTap;
  late final RouteMode mode;

  TransitItem({super.key, required this.stop, this.onTap}) {
    mode = RouteMode.fromString(stop.mode);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(mode.icon, color: mode.color),
      title: Text(stop.name),
      onTap: onTap,
      visualDensity: VisualDensity(vertical: -4),
    );
  }
}
