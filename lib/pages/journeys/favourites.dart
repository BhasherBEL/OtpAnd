import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:otpand/db/crud/favourites.dart';
import 'package:otpand/objects/favourite.dart';
import 'package:otpand/objects/history.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/pages/journeys/favourite.dart';
import 'package:otpand/utils/colors.dart';
import 'package:otpand/widgets/search/searchmodal.dart';

class FavouritesWidget extends StatefulWidget {
  final Function()? onDragComplete;

  const FavouritesWidget({super.key, this.onDragComplete});

  @override
  State<FavouritesWidget> createState() => _FavouritesWidgetState();
}

class _FavouritesWidgetState extends State<FavouritesWidget> {
  late Future<List<Favourite>> _favouritesFuture;

  Favourite? _dragSource;
  Favourite? _dragTarget;
  Offset? _dragStartOffset; // global
  Offset? _dragCurrentOffset; // global

  final GlobalKey _stackKey = GlobalKey();

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

  Offset _globalToLocal(Offset globalOffset) {
    final RenderBox? box =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      return box.globalToLocal(globalOffset);
    }
    return globalOffset;
  }

  void _onDragStarted(Favourite fav, Offset globalPosition) {
    setState(() {
      _dragSource = fav;
      _dragTarget = null;
      _dragStartOffset = globalPosition;
      _dragCurrentOffset = globalPosition;
    });
  }

  void _onDragUpdate(Offset globalPosition) {
    setState(() {
      _dragCurrentOffset = globalPosition;
    });
  }

  void _onDragEntered(Favourite fav) {
    setState(() {
      _dragTarget = fav;
    });
  }

  void _onDragExited(Favourite fav) {
    setState(() {
      if (_dragTarget == fav) _dragTarget = null;
    });
  }

  void _onDragEnd() {
    setState(() {
      _dragSource = null;
      _dragTarget = null;
      _dragStartOffset = null;
      _dragCurrentOffset = null;
    });
  }

  final List<GlobalKey> _cardKeys = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Favourites', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<Favourite>>(
            future: _favouritesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final favourites = snapshot.data ?? [];
              final items = List<Favourite?>.from(favourites);
              items.add(null);

              while (_cardKeys.length < items.length) {
                _cardKeys.add(GlobalKey());
              }
              while (_cardKeys.length > items.length) {
                _cardKeys.removeLast();
              }

              void updateDragTarget(Offset globalPosition) {
                for (int i = 0; i < items.length; i++) {
                  final fav = items[i];
                  if (fav == null) continue;
                  final key = _cardKeys[i];
                  final context = key.currentContext;
                  if (context == null) continue;
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null || !box.hasSize) continue;
                  final pos = box.localToGlobal(Offset.zero);
                  final size = box.size;
                  final rect = pos & size;
                  if (rect.contains(globalPosition)) {
                    if (_dragTarget != fav) {
                      setState(() {
                        _dragTarget = fav;
                      });
                    }
                    return;
                  }
                }
                if (_dragTarget != null) {
                  setState(() {
                    _dragTarget = null;
                  });
                }
              }

              return Stack(
                key: _stackKey,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                                await FavouriteDao().insertFromLocation(
                                  location,
                                );
                                _reload();
                              }
                            },
                            child: Center(
                              child: Icon(
                                Icons.add,
                                size: 32,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Listener(
                          onPointerDown: (event) {
                            _onDragStarted(fav, event.position);
                          },
                          onPointerMove: (event) {
                            if (_dragSource == fav) {
                              _onDragUpdate(event.position);
                            }
                            if (_dragSource != null) {
                              updateDragTarget(event.position);
                            }
                          },
                          onPointerUp: (event) {
                            if (_dragSource != null &&
                                _dragTarget != null &&
                                _dragSource != _dragTarget) {
                              History.update(
                                fromLocation: _dragSource!.toLocation(),
                                toLocation: _dragTarget!.toLocation(),
                              );
                              if (widget.onDragComplete != null) {
                                widget.onDragComplete!();
                              }
                            }
                            _onDragEnd();
                          },
                          child: Container(
                            key: _cardKeys[index],
                            child: FavouriteWidget(
                              favourite: fav,
                              onChanged: _reload,
                              color:
                                  _dragSource == fav
                                      ? Colors.blue
                                      : (_dragTarget == fav
                                          ? Colors.green
                                          : null),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  if (_dragSource != null &&
                      _dragStartOffset != null &&
                      _dragCurrentOffset != null)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _LinePainter(
                          _globalToLocal(_dragStartOffset!),
                          _globalToLocal(_dragCurrentOffset!),
                        ),
                        child: Container(),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  _LinePainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint =
        Paint()
          ..color = Colors.grey[800]!
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    final Paint circlePaint =
        Paint()
          ..color = Colors.grey[800]!
          ..style = PaintingStyle.fill;

    const double dashWidth = 1;
    const double dashSpace = 1;
    final double totalDistance = (end - start).distance;
    final Offset direction = (end - start) / totalDistance;

    double current = 0;
    while (current < totalDistance) {
      final Offset from = start + direction * current;
      final double next = (current + dashWidth).clamp(0, totalDistance);
      final Offset to = start + direction * next;
      canvas.drawLine(from, to, linePaint);
      current += dashWidth + dashSpace;
    }

    // Draw circles at start and end
    const double circleRadius = 8;
    canvas.drawCircle(start, circleRadius, circlePaint);
    canvas.drawCircle(end, circleRadius, circlePaint);
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) =>
      oldDelegate.start != start || oldDelegate.end != end;
}
