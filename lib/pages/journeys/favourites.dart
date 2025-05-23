import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:otpand/db/crud/favourites.dart';
import 'package:otpand/objects/favourite.dart';
import 'package:otpand/objs.dart';
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final fav = items[index];
                  if (fav == null) {
                    return DottedBorder(
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(16),
                      dashPattern: const [6, 3],
                      color: Colors.grey.shade400,
                      strokeWidth: 1.5,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
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
                  }
                  return Card(
                    child: Center(
                      child: Text(
                        fav.name,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
