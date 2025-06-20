import 'package:flutter/material.dart';
import 'package:otpand/objects/route.dart';

class RouteIconWidget extends StatelessWidget {
  final RouteInfo route;
  final double size;

  const RouteIconWidget({super.key, required this.route, this.size = 16});

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
              width: size * 2,
              height: size * 2,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(route.mode.icon, color: Colors.white, size: size * 1.25),
            ),
            SizedBox(width: size * 0.25),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size * 0.75,
                vertical: size * 0.4,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(size * 0.5),
              ),
              child: Text(
                route.shortName,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: size,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
