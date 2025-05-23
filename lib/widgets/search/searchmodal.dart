import 'package:flutter/material.dart';
import 'package:otpand/api.dart';
import 'package:otpand/db/crud/stops.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/utils/gnss.dart';

class SearchModal extends StatefulWidget {
  final bool showCurrentLocation;
  final bool showFavourites;
  final bool showTransitStops;

  const SearchModal({
    super.key,
    this.showCurrentLocation = true,
    this.showFavourites = true,
    this.showTransitStops = true,
  });

  static Future<Location?> show(
    BuildContext context, {
    bool showCurrentLocation = true,
    bool showFavourites = true,
    bool showTransitStops = true,
  }) {
    return showModalBottomSheet<Location?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder:
          (context) => SearchModal(
            showCurrentLocation: showCurrentLocation,
            showFavourites: showFavourites,
            showTransitStops: showTransitStops,
          ),
    );
  }

  @override
  State<SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<SearchModal> {
  final TextEditingController _controller = TextEditingController();
  String _lastSearchedText = '';
  bool _loading = false;
  String? _error;
  List<Location> _suggestions = [];
  List<Location> _allStops = [];

  @override
  void initState() {
    super.initState();
    _loadStops();
    _controller.addListener(_onTextChanged);
  }

  Future<void> _loadStops() async {
    setState(() => _loading = true);
    final stops = await StopDao().getAll();
    setState(() {
      _allStops =
          stops
              .map(
                (stop) => Location(
                  name: stop.name,
                  displayName: stop.name,
                  lat: stop.lat,
                  lon: stop.lon,
                  stop: stop,
                ),
              )
              .toList();
      _suggestions = _allStops;
      _loading = false;
    });
  }

  void _onTextChanged() {
    final text = _controller.text.trim().toLowerCase();
    if (text.isEmpty) {
      setState(() => _suggestions = _allStops);
      return;
    }
    final filteredStops =
        _allStops
            .where((stop) => stop.name.toLowerCase().contains(text))
            .toList();
    setState(() {
      _suggestions =
          filteredStops..sort((aS, bS) {
            final a = aS.name.toLowerCase();
            final b = bS.name.toLowerCase();

            if (_suggestions.isEmpty) return a.compareTo(b);

            if (a.startsWith(text) && !b.startsWith(text)) {
              return -1;
            }
            if (b.startsWith(text) && !a.startsWith(text)) {
              return 1;
            }

            if (a.length != b.length) {
              return a.length - b.length;
            }

            return a.compareTo(b);
          });
    });
  }

  Future<void> _searchAddress() async {
    final trimmedText = _controller.text.trim();
    if (trimmedText.isEmpty || trimmedText == _lastSearchedText) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _lastSearchedText = trimmedText;
    final location = await geoCodeNominatimApi(trimmedText);
    if (!mounted) return;
    if (location != null) {
      Navigator.of(context).pop(location);
    } else {
      setState(() {
        _error = "No location found.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: safePadding.top + 8,
                    left: 16,
                    right: 16,
                    bottom: 8,
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Search for a location...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon:
                          _loading
                              ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                              : IconButton(
                                icon: Icon(Icons.search),
                                onPressed: _searchAddress,
                              ),
                      errorText: _error,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                    ),
                    onSubmitted: (_) => _searchAddress(),
                  ),
                ),
                if (widget.showCurrentLocation)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: Icon(Icons.my_location, color: Colors.blue),
                      title: Text("Current Location"),
                      onTap: () async {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        try {
                          final loc = await getCurrentLocation();
                          if (!mounted) return;
                          if (loc != null) {
                            Navigator.of(context).pop(loc);
                          } else {
                            setState(() {
                              _error = "Location unavailable.";
                              _loading = false;
                            });
                          }
                        } catch (e) {
                          setState(() {
                            _error = "Location error: ${e.toString()}";
                            _loading = false;
                          });
                        }
                      },
                    ),
                  ),
                if (widget.showFavourites)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Favourite",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                if (widget.showTransitStops)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Transit Stop",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child:
                      _loading
                          ? Center(child: CircularProgressIndicator())
                          : ListView.builder(
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final stop = _suggestions[index];
                              return ListTile(
                                title: Text(stop.displayName),
                                onTap: () => Navigator.of(context).pop(stop),
                              );
                            },
                          ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: safePadding.bottom + 8,
                    top: 8,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _searchAddress,
                      child: const Text("Search address"),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
