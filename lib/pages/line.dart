import 'package:flutter/material.dart';
import 'package:otpand/db/crud/directions.dart';
import 'package:otpand/db/crud/stops.dart';
import 'package:otpand/objects/direction.dart';
import 'package:otpand/objects/route.dart';
import 'package:otpand/objects/stop.dart';
import 'package:timelines_plus/timelines_plus.dart';

class LinePage extends StatefulWidget {
  final RouteInfo route;
  const LinePage({super.key, required this.route});

  @override
  State<LinePage> createState() => _LinePageState();
}

class _LinePageState extends State<LinePage> {
  late Future<List<Direction>> _directionFuture;

  @override
  void initState() {
    super.initState();
    _directionFuture = DirectionDao().getFromRoute(widget.route.gtfsId);
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    print(route.gtfsId);
    return Scaffold(
      appBar: AppBar(
        title: Text(route.longName),
        backgroundColor: route.color ?? Theme.of(context).primaryColor,
        foregroundColor: route.textColor ?? Colors.white,
      ),
      body: FutureBuilder<List<Direction>>(
        future: _directionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading : ${snapshot.error}'));
          }
          final directions = snapshot.data ?? [];
          if (directions.isEmpty) {
            return const Center(
              child: Text('No directions found for this line.'),
            );
          }

          return FutureBuilder<List<Stop>>(
            future: StopDao().getFromDirection(directions.first.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading : ${snapshot.error}'));
              }

              final stops = snapshot.data ?? [];
              print('Stops: ${stops.length}');

              return Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: route.color ?? Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            route.shortName,
                            style: TextStyle(
                              color: route.textColor ?? Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            route.longName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Chip(
                          label: Text(route.mode.name.toUpperCase()),
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: SingleChildScrollView(
                        child: FixedTimeline.tileBuilder(
                          theme: TimelineThemeData(
                            nodePosition: 0,
                            color: route.color ?? Colors.blueAccent,
                            indicatorTheme: IndicatorThemeData(
                              size: 22,
                              position: 0,
                            ),
                            connectorTheme: ConnectorThemeData(
                              thickness: 2.0,
                              color: route.color ?? Colors.blueAccent,
                            ),
                          ),
                          builder: TimelineTileBuilder.connected(
                            connectionDirection: ConnectionDirection.before,
                            itemCount: stops.length,
                            contentsBuilder: (context, index) {
                              final stop = stops[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  bottom: 8.0,
                                  top: 8.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stop.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (stop.platformCode != null &&
                                        stop.platformCode!.isNotEmpty)
                                      Text(
                                        'Platform: ${stop.platformCode}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                            indicatorBuilder: (context, index) {
                              if (index == 0) {
                                return DotIndicator(
                                  size: 22,
                                  color: Colors.green,
                                  child: Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                );
                              } else if (index == stops.length - 1) {
                                return DotIndicator(
                                  size: 22,
                                  color: Colors.red,
                                  child: Icon(
                                    Icons.flag,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                );
                              } else {
                                return OutlinedDotIndicator(
                                  size: 18,
                                  color: route.color ?? Colors.blue,
                                  backgroundColor: Colors.white,
                                  borderWidth: 2.0,
                                );
                              }
                            },
                            connectorBuilder: (context, index, type) {
                              if (index == 0) return null;
                              return const SolidLineConnector();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
