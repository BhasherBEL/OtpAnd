import 'package:flutter/material.dart';
import 'package:otpand/objects/route.dart';

class RouteIconWidget extends StatelessWidget {
  final RouteInfo route;

  const RouteIconWidget({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final Color modeColor = route.mode.color;
    final Color bgColor = route.color ?? modeColor;
    final Color textColor = route.textColor ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(route.mode.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                route.shortName,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
