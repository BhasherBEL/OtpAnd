import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:otpand/api.dart';
import 'package:otpand/db/crud/stops.dart';
import 'package:otpand/objects/location.dart';

import 'package:otpand/utils/gnss.dart';
import 'package:otpand/widgets/search/searchmodal.dart';

class SearchBarWidget extends StatefulWidget {
  final String? initialValue;
  final Location? selectedLocation;
  final void Function(Location?) onLocationSelected;
  final String hintText;

  const SearchBarWidget({
    super.key,
    this.initialValue,
    this.selectedLocation,
    required this.onLocationSelected,
    this.hintText = 'Search for a location...',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  String? _selectedText;

  @override
  void initState() {
    super.initState();
    _selectedText = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _selectedText = widget.initialValue;
      });
    }
  }

  Future<void> _openSearchModal() async {
    final result = await SearchModal.show(context);
    if (result != null) {
      setState(() {
        _selectedText = result.displayName;
      });
      widget.onLocationSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _openSearchModal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedText ?? widget.hintText,
                    style: TextStyle(
                      color:
                          _selectedText == null
                              ? Colors.grey[500]
                              : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.selectedLocation != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Selected: ${widget.selectedLocation!.displayName}',
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _FullScreenSearchModal extends StatefulWidget {
  const _FullScreenSearchModal();

  @override
  State<_FullScreenSearchModal> createState() => _FullScreenSearchModalState();
}

class _FullScreenSearchModalState extends State<_FullScreenSearchModal> {
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
        _error = 'No location found.';
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
                      hintText: 'Search for a location...',
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Icon(Icons.my_location, color: Colors.blue),
                    title: Text('Current Location'),
                    onTap: () async {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      try {
                        final loc = await getCurrentLocation();
                        if (!mounted) return;
                        if (loc != null) {
                          if (context.mounted) Navigator.of(context).pop(loc);
                        } else {
                          setState(() {
                            _error = 'Location unavailable.';
                            _loading = false;
                          });
                        }
                      } on TimeoutException catch (_) {
                        setState(() {
                          _error = 'Location request timed out.';
                          _loading = false;
                        });
                      } on LocationServiceDisabledException catch (_) {
                        setState(() {
                          _error = 'Location services are disabled.';
                          _loading = false;
                        });
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Favourite',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Transit Stop',
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
                      child: const Text('Search address'),
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
