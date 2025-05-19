import 'package:flutter/material.dart';
import 'package:otpand/db/crud/stops.dart';
import 'package:otpand/objects/stop.dart';
import 'package:otpand/pages/stop.dart';
import 'package:otpand/utils.dart';

class StopsPage extends StatefulWidget {
  const StopsPage({super.key});

  @override
  State<StopsPage> createState() => _StopsPageState();
}

class _StopsPageState extends State<StopsPage> {
  late Future<List<Stop>> _stopsFuture;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _stopsFuture = StopDao().getAll();
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
            child: FutureBuilder<List<Stop>>(
              future: _stopsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading stops: ${snapshot.error}'),
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

                final sortedStops =
                    filteredStops..sort((aS, bS) {
                      final a = aS.name.toLowerCase();
                      final b = bS.name.toLowerCase();

                      if (_filter.isEmpty) return a.compareTo(b);

                      if (a.startsWith(_filter) && !b.startsWith(_filter)) {
                        return -1;
                      }
                      if (b.startsWith(_filter) && !a.startsWith(_filter)) {
                        return 1;
                      }

                      if (a.length != b.length) {
                        return a.length - b.length;
                      }

                      return a.compareTo(b);
                    });

                return ListView.builder(
                  itemCount: sortedStops.length,
                  itemBuilder: (context, index) {
                    final stop = sortedStops[index];
                    // Use stop.mode if available, otherwise default to "BUS"
                    final mode = (stop as dynamic).mode ?? "BUS";
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
