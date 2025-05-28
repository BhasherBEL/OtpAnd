import 'package:flutter/material.dart';
import 'package:otpand/objects/favourite.dart';
import 'package:otpand/db/crud/favourites.dart';
import 'package:otpand/objects/route.dart';
import 'package:otpand/pages/stop.dart';
import 'package:otpand/utils/colors.dart';

class FavouriteWidget extends StatelessWidget {
  const FavouriteWidget({
    super.key,
    required this.favourite,
    required this.onChanged,
    this.color,
  });

  final Favourite favourite;
  final VoidCallback onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final RouteMode mode = RouteMode.fromString(favourite.stop?.mode);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (favourite.stop != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StopPage(stop: favourite.stop!),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primary500, width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (favourite.stop != null && favourite.stop!.mode != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(right: 8),
                      child: Icon(mode.icon, color: mode.color, size: 20),
                    ),
                  if (favourite.isContact)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.contacts, size: 20),
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        favourite.name,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 24),
                    onSelected: (value) async {
                      if (value == 'rename') {
                        final controller = TextEditingController(
                          text: favourite.name,
                        );
                        final newName = await showDialog<String>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Rename Favourite'),
                                content: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(
                                          context,
                                        ).pop(controller.text.trim()),
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                        );
                        if (newName != null &&
                            newName.isNotEmpty &&
                            newName != favourite.name) {
                          await FavouriteDao().insert({
                            'id': favourite.id,
                            'name': newName,
                            'lat': favourite.lat,
                            'lon': favourite.lon,
                            'stopGtfsId': favourite.stop?.gtfsId,
                          });
                          onChanged();
                        }
                      } else if (value == 'delete') {
                        await FavouriteDao().delete(favourite.id.toString());
                        onChanged();
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Text('Rename'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
