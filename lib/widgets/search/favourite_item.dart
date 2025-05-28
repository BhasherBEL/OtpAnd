import 'package:flutter/material.dart';
import 'package:otpand/objects/favourite.dart';

class FavouriteItem extends StatelessWidget {
  final Favourite favourite;
  final VoidCallback? onTap;

  const FavouriteItem({super.key, required this.favourite, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.star, color: Colors.amber),
      title: Text(favourite.name, overflow: TextOverflow.ellipsis),
      onTap: onTap,
      visualDensity: VisualDensity(vertical: -4),
    );
  }
}
