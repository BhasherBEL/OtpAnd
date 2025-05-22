import 'package:flutter/material.dart';
import 'package:otpand/db/crud/stops.dart';
import 'package:otpand/objects/stop.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/pages/stop.dart';
import 'package:otpand/utils.dart';
import 'package:otpand/utils/gnss.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StopsPage extends StatefulWidget {
  const StopsPage({super.key});

  @override
  State<StopsPage> createState() => _StopsPageState();
}

class _StopsPageState extends State<StopsPage> {
  late Future<List<Stop>> _stopsFuture;
  String _filter = '';
  bool _sortByDistance = false;
  Map<String, double>? _stopDistances;
  bool _loadingDistances = false;

  @override
  void initState() {
    super.initState();
    _loadSortSetting();
    _stopsFuture = StopDao().getAll();
  }

  Future<void> _loadSortSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final sort = prefs.getBool('otp_sort_stops_by_distance') ?? false;
    if (sort) {
      setState(() {
        _sortByDistance = true;
        _loadingDistances = true;
      });
      await _calculateDistances();
    } else {
      setState(() {
        _sortByDistance = false;
        _stopDistances = null;
        _loadingDistances = false;
      });
    }
  }

  Future<void> _calculateDistances() async {
    try {
      final loc = await getCurrentLocation();
      if (loc == null) {
        setState(() {
          _stopDistances = null;
          _loadingDistances = false;
        });
        return;
      }
      final stops = await StopDao().getAll();
      final locations =
          stops
              .map(
                (s) => Location(
                  name: s.name,
                  displayName: s.name,
                  lat: s.lat,
                  lon: s.lon,
                ),
              )
              .toList();
      final distancesList = await distancesToCurrentLocation(locations);
      final distances = <String, double>{};
      for (int i = 0; i < stops.length; i++) {
        final d = distancesList[i];
        if (d != null) {
          distances[stops[i].gtfsId] = d;
        }
      }
      setState(() {
        _stopDistances = distances;
        _loadingDistances = false;
      });
    } catch (_) {
      setState(() {
        _stopDistances = null;
        _loadingDistances = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Filter by name or platform',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _filter = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child:
                _sortByDistance && _loadingDistances
                    ? const Center(child: CircularProgressIndicator())
                    : FutureBuilder<List<Stop>>(
                      future: _stopsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading stops: ${snapshot.error}',
                            ),
                          );
                        }
                        final stops = snapshot.data ?? [];
                        final filteredStops =
                            stops.where((stop) {
                              final search = _filter;
                              return search.isEmpty ||
                                  stop.name.toLowerCase().contains(search) ||
                                  (stop.platformCode != null &&
                                      stop.platformCode!.toLowerCase().contains(
                                        search,
                                      ));
                            }).toList();

                        if (filteredStops.isEmpty) {
                          return const Center(child: Text('No stops found.'));
                        }

                        List<Stop> sortedStops = List.from(filteredStops);

                        if (_sortByDistance && _stopDistances != null) {
                          sortedStops.sort((a, b) {
                            final ad = _stopDistances![a.gtfsId];
                            final bd = _stopDistances![b.gtfsId];
                            if (ad == null && bd == null) return 0;
                            if (ad == null) return 1;
                            if (bd == null) return -1;
                            return ad.compareTo(bd);
                          });
                        } else {
                          sortedStops.sort((aS, bS) {
                            final a = aS.name.toLowerCase();
                            final b = bS.name.toLowerCase();

                            if (_filter.isEmpty) return a.compareTo(b);

                            if (a.startsWith(_filter) &&
                                !b.startsWith(_filter)) {
                              return -1;
                            }
                            if (b.startsWith(_filter) &&
                                !a.startsWith(_filter)) {
                              return 1;
                            }

                            if (a.length != b.length) {
                              return a.length - b.length;
                            }

                            return a.compareTo(b);
                          });
                        }

                        return ListView.builder(
                          itemCount: sortedStops.length,
                          itemBuilder: (context, index) {
                            final stop = sortedStops[index];
                            // Use stop.mode if available, otherwise default to "BUS"
                            final mode = (stop as dynamic).mode ?? "BUS";
                            final distance =
                                _sortByDistance && _stopDistances != null
                                    ? _stopDistances![stop.gtfsId]
                                    : null;
                            return ListTile(
                              leading: Icon(
                                iconForMode(mode),
                                color: colorForMode(mode),
                              ),
                              title: Text(stop.name),
                              subtitle:
                                  stop.platformCode != null &&
                                          stop.platformCode!.isNotEmpty
                                      ? Text('Platform: ${stop.platformCode}')
                                      : null,
                              trailing:
                                  distance != null
                                      ? Text(displayDistance(distance))
                                      : null,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StopPage(stop: stop),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
