import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:otpand/api.dart';
import 'package:otpand/objects/contact.dart';
import 'package:otpand/objects/location.dart';
import 'package:otpand/objects/stop.dart';
import 'package:otpand/utils/gnss.dart';
import 'package:otpand/objects/favourite.dart';
import 'package:otpand/widgets/map_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:otpand/widgets/search/contact_item.dart';
import 'package:otpand/widgets/search/favourite_item.dart';
import 'package:otpand/widgets/search/transit_item.dart';

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
  List<Favourite> _favourites = [];
  List<Favourite> _filteredFavourites = [];
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _loadStops();
    Stop.currentStops.addListener(_loadStops);
    _loadFavourites();
    Favourite.currentFavourites.addListener(_loadFavourites);
    _loadContacts();
    ContactInfo.currentContacts.addListener(_loadContacts);
    unawaited(ContactInfo.loadAll());
    _controller.addListener(_onTextChanged);
  }

  void _loadContacts() {
    try {
      final filtered =
          ContactInfo.currentContacts.value
              .where((c) => c.addresses.isNotEmpty)
              .toList();
      if (mounted) {
        setState(() {
          _contacts = filtered;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load contacts: ${e.toString()}';
        });
      }
    }
  }

  void _loadStops() {
    _allStops =
        Stop.currentStops.value
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
  }

  void _loadFavourites() {
    _favourites = Favourite.currentFavourites.value;
    if (mounted) {
      setState(() {
        _filteredFavourites = _favourites;
      });
    }
  }

  void _onTextChanged() {
    final text = _controller.text.trim().toLowerCase();
    if (text.isEmpty) {
      setState(() {
        _suggestions = [];
        _filteredFavourites = _favourites;
        _filteredContacts = [];
      });
      return;
    }
    final filteredStops =
        _allStops
            .where((stop) => stop.name.toLowerCase().contains(text))
            .toList();
    final filteredFavourites =
        _favourites
            .where((fav) => fav.name.toLowerCase().contains(text))
            .toList();
    final filteredContacts =
        _contacts
            .where(
              (contact) => contact.displayName.toLowerCase().contains(text),
            )
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
      _filteredFavourites = filteredFavourites;
      _filteredContacts = filteredContacts;
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
                Flexible(
                  child:
                      _loading
                          ? Center(child: CircularProgressIndicator())
                          : ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              if (widget.showCurrentLocation)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.my_location,
                                      color: Colors.blue,
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    title: Text('Current Location'),
                                    onTap: () async {
                                      setState(() {
                                        _loading = true;
                                        _error = null;
                                      });
                                      try {
                                        final loc = await getCurrentLocation();
                                        if (!context.mounted) return;
                                        if (loc != null) {
                                          Navigator.of(context).pop(loc);
                                        } else {
                                          setState(() {
                                            _error = 'Location unavailable.';
                                            _loading = false;
                                          });
                                        }
                                      } on TimeoutException catch (_) {
                                        setState(() {
                                          _error =
                                              'Location request timed out.';
                                          _loading = false;
                                        });
                                      } on LocationServiceDisabledException catch (
                                        _
                                      ) {
                                        setState(() {
                                          _error =
                                              'Location services are disabled.';
                                          _loading = false;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: Icon(Icons.map, color: Colors.green),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  title: Text('Choose from the map'),
                                  onTap: () async {
                                    final loc = await Navigator.of(
                                      context,
                                    ).push<Location>(
                                      MaterialPageRoute<Location>(
                                        builder: (context) => MapPicker(),
                                      ),
                                    );
                                    if (loc != null && context.mounted) {
                                      Navigator.of(context).pop(loc);
                                    }
                                  },
                                ),
                              ),
                              if (widget.showFavourites &&
                                  _filteredFavourites.isNotEmpty) ...[
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
                                ..._filteredFavourites.map(
                                  (fav) => FavouriteItem(
                                    favourite: fav,
                                    onTap:
                                        () => Navigator.of(
                                          context,
                                        ).pop(fav.toLocation()),
                                  ),
                                ),
                              ],
                              if (widget.showFavourites &&
                                  _filteredFavourites.isEmpty &&
                                  _controller.text.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'No favourites yet.',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              if (_filteredContacts.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Contacts',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                                ..._filteredContacts.map(
                                  (contact) => ContactItem(
                                    contact: contact,
                                    onTap:
                                        (location) =>
                                            Navigator.of(context).pop(location),
                                    rootContext: context,
                                  ),
                                ),
                              ],
                              if (widget.showTransitStops &&
                                  _suggestions.isNotEmpty) ...[
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
                                ..._suggestions.map(
                                  (stop) => TransitItem(
                                    stop: stop.stop!,
                                    onTap:
                                        () => Navigator.of(context).pop(stop),
                                  ),
                                ),
                              ],
                            ],
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
