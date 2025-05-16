import 'package:flutter/material.dart';
import 'package:otpand/db/crud/routes.dart';
import 'package:otpand/objects/route.dart';
import 'package:otpand/pages/line.dart';

class LinesPage extends StatefulWidget {
  const LinesPage({super.key});

  @override
  State<LinesPage> createState() => _LinesPageState();
}

class _LinesPageState extends State<LinesPage> {
  late Future<List<RouteInfo>> _routesFuture;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _routesFuture = RouteDao().getAll();
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
                hintText: 'Filter by name or number',
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
            child: FutureBuilder<List<RouteInfo>>(
              future: _routesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading routes: ${snapshot.error}'),
                  );
                }
                final routes = snapshot.data ?? [];
                final filteredRoutes =
                    routes.where((route) {
                      final search = _filter;
                      return search.isEmpty ||
                          route.shortName.toLowerCase().contains(search) ||
                          route.longName.toLowerCase().contains(search);
                    }).toList();
                if (filteredRoutes.isEmpty) {
                  return const Center(child: Text('No routes found.'));
                }
                return ListView.builder(
                  itemCount: filteredRoutes.length,
                  itemBuilder: (context, index) {
                    final route = filteredRoutes[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: route.color ?? Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              route.shortName,
                              style: TextStyle(
                                color: route.textColor ?? Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      title: Text(route.longName),
                      subtitle: Text(route.mode.name.toUpperCase()),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LinePage(route: route),
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
