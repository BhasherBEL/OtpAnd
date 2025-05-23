import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:otpand/db/crud/favourites.dart';
import 'package:otpand/objects/favourite.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/pages/journeys/favourite.dart';
import 'package:otpand/utils/colors.dart';
import 'package:otpand/widgets/search/searchmodal.dart';

class FavouritesWidget extends StatefulWidget {
  const FavouritesWidget({super.key});

  @override
  State<FavouritesWidget> createState() => _FavouritesWidgetState();
}

class _FavouritesWidgetState extends State<FavouritesWidget> {
  late Future<List<Favourite>> _favouritesFuture;

  @override
  void initState() {
    super.initState();
    _favouritesFuture = FavouriteDao().getAll();
  }

  void _reload() {
    setState(() {
      _favouritesFuture = FavouriteDao().getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "Favourites",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        FutureBuilder<List<Favourite>>(
          future: _favouritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final favourites = snapshot.data ?? [];
            final items = List<Favourite?>.from(favourites);
            items.add(null);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 50,
                ),
                itemBuilder: (context, index) {
                  final fav = items[index];
                  if (fav == null) {
                    return DottedBorder(
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(8),
                      dashPattern: const [6, 3],
                      color: primary500,
                      strokeWidth: 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final Location? location = await SearchModal.show(
                            context,
                            showCurrentLocation: false,
                            showFavourites: false,
                          );
                          if (location != null) {
                            await FavouriteDao().insertFromLocation(location);
                            _reload();
                          }
                        },
                        child: Center(
                          child: Icon(Icons.add, size: 32, color: Colors.blue),
                        ),
                      ),
                    );
                  } else {
                    return FavouriteWidget(favourite: fav, onChanged: _reload);
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
