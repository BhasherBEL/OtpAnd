import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otpand/blocs/plans/bloc.dart';
import 'package:otpand/blocs/plans/events.dart';
import 'package:otpand/blocs/plans/helpers.dart';
import 'package:otpand/blocs/plans/repository.dart';
import 'package:otpand/blocs/plans/states.dart';
import 'package:otpand/db/crud/profiles.dart';
import 'package:otpand/db/crud/search_history.dart';
import 'package:otpand/objects/location.dart';
import 'package:otpand/objects/profile.dart';
import 'package:otpand/pages/profile.dart';
import 'package:otpand/pages/routes/plans_list.dart';
import 'package:otpand/utils/colors.dart';
import 'package:otpand/widgets/search/searchbar.dart';
import 'package:otpand/widgets/datetime_picker.dart';
import 'package:dotted_line/dotted_line.dart';

class RoutesPageBlocProvider extends StatelessWidget {
  final Location fromLocation;
  final Location toLocation;
  final Profile profile;
  final DateTimePickerValue dateTimeValue;

  const RoutesPageBlocProvider({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    required this.profile,
    required this.dateTimeValue,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlansBloc(PlansRepository()),
      child: RoutesPage(
        fromLocation: fromLocation,
        toLocation: toLocation,
        profile: profile,
        dateTimeValue: dateTimeValue,
      ),
    );
  }
}

class RoutesPage extends StatefulWidget {
  final Location fromLocation;
  final Location toLocation;
  final Profile profile;
  final DateTimePickerValue dateTimeValue;

  const RoutesPage({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    required this.profile,
    required this.dateTimeValue,
  });

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  late Location? fromLocation;
  late Location? toLocation;
  late Profile profile;
  late DateTimePickerValue dateTimeValue;
  List<Profile> profiles = [];

  @override
  void initState() {
    super.initState();
    fromLocation = widget.fromLocation;
    toLocation = widget.toLocation;
    profile = widget.profile;
    dateTimeValue = widget.dateTimeValue;
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final loadedProfiles = await ProfileDao.getAll();
    setState(() {
      profiles = loadedProfiles;
      if (!profiles.any((p) => p.id == profile.id)) {
        profiles.insert(0, profile);
      }
    });
    _fetchPlans();
  }

  void _fetchPlans() {
    if (fromLocation == null || toLocation == null) return;

    unawaited(
      SearchHistoryDao().saveSearch(
          fromLocation: fromLocation!,
          toLocation: toLocation!,
          profile: profile),
    );

    final variables = PlansQueryVariables(
      fromLocation: fromLocation!,
      toLocation: toLocation!,
      profile: profile,
      dateTimeValue: dateTimeValue,
    );

    context.read<PlansBloc>().add(LoadPlans(variables));
  }

  void _onFromLocationChanged(Location? location) {
    setState(() {
      fromLocation = location;
    });
    if (location != null && toLocation != null) {
      _fetchPlans();
    }
  }

  void _onToLocationChanged(Location? location) {
    setState(() {
      toLocation = location;
    });
    if (fromLocation != null && location != null) {
      _fetchPlans();
    }
  }

  void _onSwap() {
    setState(() {
      final temp = fromLocation;
      fromLocation = toLocation;
      toLocation = temp;
    });
    if (fromLocation != null && toLocation != null) {
      _fetchPlans();
    }
  }

  void _onDateTimeChanged(DateTimePickerValue value) {
    setState(() {
      dateTimeValue = value;
    });
    if (fromLocation != null && toLocation != null) {
      _fetchPlans();
    }
  }

  Widget _buildSearchCard() {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            offset: Offset(0, 4),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 10,
            left: 10,
            right: 10,
            bottom: 10,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SearchBarWidget(
                          initialValue: fromLocation?.displayName,
                          selectedLocation: fromLocation,
                          hintText: 'From',
                          onLocationSelected: _onFromLocationChanged,
                        ),
                        DottedLine(
                          direction: Axis.horizontal,
                          dashColor: Colors.grey,
                        ),
                        SearchBarWidget(
                          initialValue: toLocation?.displayName,
                          selectedLocation: toLocation,
                          hintText: 'To',
                          onLocationSelected: _onToLocationChanged,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.swap_vert, color: primary500, size: 40),
                    onPressed: _onSwap,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Profile picker row (full width, just below toLocation)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Profile>(
                      value: profiles.isNotEmpty
                          ? profiles.firstWhere(
                              (p) => p.id == profile.id,
                              orElse: () => profile,
                            )
                          : profile,
                      items: profiles.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                backgroundColor: p.color,
                                radius: 10,
                                child: p.hasTemporaryEdits
                                    ? Icon(
                                        Icons.edit,
                                        size: 12,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  p.name.isNotEmpty ? p.name : 'Profile ${p.id}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (p.hasTemporaryEdits)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (selected) {
                        if (selected == null) return;
                        setState(() {
                          profile = selected;
                        });
                        if (fromLocation != null && toLocation != null) {
                          _fetchPlans();
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Profile',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: primary500.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TextButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.of(
                          context,
                        ).push<Profile>(
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(profile: profile),
                          ),
                        );
                        if (updated != null) {
                          setState(() {
                            profile = updated;
                            // Update existing profile
                            profiles = profiles
                                .map(
                                  (p) => p.id == updated.id ? updated : p,
                                )
                                .toList();
                          });
                          if (fromLocation != null && toLocation != null) {
                            _fetchPlans();
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.settings,
                        size: 18,
                        color: primary500,
                      ),
                      label: const Text(
                        'Options',
                        style: TextStyle(color: primary500),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, {
            'fromLocation': fromLocation,
            'toLocation': toLocation,
            'profile': profile,
          });
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(statusBarColor: primary500),
        child: Scaffold(
          backgroundColor: primary50,
          body: SafeArea(
            child: BlocBuilder<PlansBloc, PlansState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 200,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: primary500),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'How do we get there?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildSearchCard(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: DateTimePicker(
                          value: dateTimeValue,
                          onChanged: _onDateTimeChanged,
                        ),
                      ),
                      PlansListWidget(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
