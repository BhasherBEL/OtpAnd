import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:otpand/objects/stop.dart';
import 'package:intl/intl.dart';

import 'package:otpand/objects/timed_stop.dart';
import 'package:otpand/objects/timed_pattern.dart';
import 'package:otpand/api/stop.dart' as stop_api;
import 'package:otpand/pages/stop/hour_departures.dart';
import 'package:otpand/utils.dart';
import 'package:otpand/utils/colors.dart';
import 'package:otpand/utils/route_colors.dart';
import 'package:otpand/widgets/departure.dart';

class StopPage extends StatefulWidget {
  final Stop stop;

  const StopPage({super.key, required this.stop});

  @override
  State<StopPage> createState() => _StopPageState();
}

class _StopPageState extends State<StopPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  List<TimedStop> _departures = [];
  bool _loading = false;
  bool _autoUpdateEnabled = false;
  DateTime? _lastUpdate;
  Timer? _timer;
  late AnimationController _rotationController;
  bool _isInForeground = true;

  bool _timetableLoading = false;
  DateTime _selectedDate = DateTime.now();
  List<TimedPattern> _timedPatterns = [];

  final Set<String> _selectedRoutes = {};
  List<String> _availableRoutes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fetchDepartures();
    _autoUpdateEnabled = true;
    if (_autoUpdateEnabled) {
      _startAutoUpdate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _rotationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _startAutoUpdate() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_isInForeground && _tabController.index == 0) {
        _fetchDepartures();
      }
    });
  }

  void _stopAutoUpdate() {
    _timer?.cancel();
    _timer = null;
  }

  void _toggleAutoUpdate() {
    setState(() {
      _autoUpdateEnabled = !_autoUpdateEnabled;
      if (_autoUpdateEnabled) {
        _startAutoUpdate();
        if (_isInForeground) {
          _fetchDepartures();
        }
      } else {
        _stopAutoUpdate();
      }
    });
  }

  Future<void> _fetchDepartures() async {
    if (!_isInForeground) return;
    setState(() {
      _loading = true;
    });
    unawaited(_rotationController.repeat());
    try {
      final departures = await stop_api.fetchNextDepartures(widget.stop);
      setState(() {
        _departures = departures;
        _lastUpdate = DateTime.now();
        _loading = false;
      });
    } on Exception catch (e, s) {
      debugPrintStack(stackTrace: s, label: 'Error fetching departures: $e');
      setState(() {
        _departures = [];
        _loading = false;
      });
    }
    _rotationController.stop();
    _rotationController.reset();
  }

  Future<void> _fetchTimetable() async {
    setState(() {
      _timetableLoading = true;
    });
    try {
      final timedPatterns = await stop_api.fetchTimetable(
        widget.stop,
        _selectedDate,
      );

      setState(() {
        _timedPatterns = timedPatterns;
        _timetableLoading = false;
        _updateAvailableRoutes();
      });
    } on Exception catch (e, s) {
      debugPrintStack(stackTrace: s, label: 'Error fetching timetable: $e');
      setState(() {
        _timedPatterns = [];
        _timetableLoading = false;
        _availableRoutes.clear();
      });
    }
  }

  void _updateAvailableRoutes() {
    final routeFrequency = <String, int>{};
    for (final pattern in _timedPatterns) {
      final routeName = pattern.route.shortName;
      routeFrequency[routeName] =
          (routeFrequency[routeName] ?? 0) + pattern.timedStops.length;
    }

    _availableRoutes =
        routeFrequency.keys.toList()..sort((a, b) {
          final aSelected = _selectedRoutes.contains(a);
          final bSelected = _selectedRoutes.contains(b);

          if (aSelected && !bSelected) return -1;
          if (!aSelected && bSelected) return 1;

          return routeFrequency[b]!.compareTo(routeFrequency[a]!);
        });
  }

  void _toggleRouteFilter(String routeName) {
    setState(() {
      if (_selectedRoutes.contains(routeName)) {
        _selectedRoutes.remove(routeName);
      } else {
        _selectedRoutes.add(routeName);
      }
      _updateAvailableRoutes();
    });
  }

  List<TimedStop> _getFilteredDepartures(List<TimedStop> departures) {
    if (_selectedRoutes.isEmpty) return departures;

    return departures.where((stop) {
      final routeName =
          stop.pattern?.route.shortName ??
          stop.trip?.route?.shortName ??
          'Unknown';
      return _selectedRoutes.contains(routeName);
    }).toList();
  }

  String _lastUpdateText() {
    if (_lastUpdate == null) return 'Never updated';
    final now = DateTime.now();
    final diff = now.difference(_lastUpdate!);
    if (diff.inSeconds < 10) return 'Just now';
    return '${displayTime(diff.inSeconds)} ago';
  }

  String _getDateDisplayText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    final difference = selectedDay.difference(today).inDays;

    switch (difference) {
      case -1:
        return 'Yesterday';
      case 0:
        return 'Today';
      case 1:
        return 'Tomorrow';
      default:
        return DateFormat('EEEE, MMMM d, y').format(date);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isInForeground = state == AppLifecycleState.resumed;
    });
    if (_isInForeground && _autoUpdateEnabled && _tabController.index == 0) {
      _fetchDepartures();
    }
  }

  Widget _buildRightNowTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle:
                        _loading ? _rotationController.value * 6.28319 * 2 : 0,
                    child: IconButton(
                      icon: Icon(
                        _autoUpdateEnabled
                            ? Icons.autorenew
                            : Icons.autorenew_outlined,
                        color: _autoUpdateEnabled ? Colors.blue : Colors.grey,
                      ),
                      tooltip:
                          _autoUpdateEnabled
                              ? (_loading
                                  ? 'Updating...'
                                  : 'Disable automatic update')
                              : 'Enable automatic update',
                      onPressed: _loading ? null : _toggleAutoUpdate,
                    ),
                  );
                },
              ),
              if (_autoUpdateEnabled)
                GestureDetector(
                  onTap: _loading ? null : _fetchDepartures,
                  child: Text(
                    _lastUpdateText(),
                    style: TextStyle(
                      color:
                          _loading
                              ? Colors.grey.shade500
                              : Colors.blue.shade300,
                      fontWeight: FontWeight.w500,
                      decoration: _loading ? null : TextDecoration.underline,
                      decorationColor: Colors.blue.shade300,
                    ),
                  ),
                ),
              if (!_autoUpdateEnabled)
                TextButton(
                  onPressed: _loading ? null : _toggleAutoUpdate,
                  child: Text(
                    'No live update',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child:
              _loading && _departures.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _departures.isEmpty
                  ? const Center(child: Text('No upcoming departures.'))
                  : ListView.builder(
                    itemCount: _departures.length,
                    itemBuilder: (context, index) {
                      final timedStop = _departures[index];
                      return DepartureWidget(timedStop: timedStop);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildTimetableTab() {
    final allDepartures = _timedPatterns.expand(
      (pattern) => pattern.timedStops,
    );

    final filteredDepartures = _getFilteredDepartures(allDepartures.toList());

    final Map<int, List<TimedStop>> groupedDepartures = filteredDepartures
        .fold<Map<int, List<TimedStop>>>({}, (
          Map<int, List<TimedStop>> groups,
          TimedStop stop,
        ) {
          final scheduledDeparture = stop.departure.scheduledDateTime;
          if (scheduledDeparture == null) return groups;
          groups
              .putIfAbsent(
                stop.departure.scheduledDateTime!.hour,
                () => <TimedStop>[],
              )
              .add(stop);
          return groups;
        });

    final sortedHours = groupedDepartures.keys.toList();
    sortedHours.sort();

    return _timetableLoading
        ? const Center(child: CircularProgressIndicator())
        : groupedDepartures.isEmpty && _timedPatterns.isNotEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No timetable data available.'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchTimetable,
                child: const Text('Load Timetable'),
              ),
            ],
          ),
        )
        : CustomScrollView(
          slivers: [
            // Date picker section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        final previousDay = _selectedDate.subtract(
                          const Duration(days: 1),
                        );
                        setState(() {
                          _selectedDate = previousDay;
                          _timedPatterns = [];
                        });
                        unawaited(_fetchTimetable());
                      },
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous day',
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 1),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                          );
                          if (date != null && date != _selectedDate) {
                            if (mounted) {
                              setState(() {
                                _selectedDate = date;
                                _timedPatterns = [];
                              });
                            }
                            unawaited(_fetchTimetable());
                          }
                        },
                        child: Text(
                          _getDateDisplayText(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final nextDay = _selectedDate.add(
                          const Duration(days: 1),
                        );
                        setState(() {
                          _selectedDate = nextDay;
                          _timedPatterns = [];
                        });
                        unawaited(_fetchTimetable());
                      },
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next day',
                    ),
                  ],
                ),
              ),
            ),
            // Route filter section
            if (_availableRoutes.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.filter_list, size: 25),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _availableRoutes.length,
                            separatorBuilder:
                                (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final routeName = _availableRoutes[index];
                              final isSelected = _selectedRoutes.contains(
                                routeName,
                              );

                              final pattern = _timedPatterns
                                  .cast<TimedPattern?>()
                                  .firstWhere(
                                    (pattern) =>
                                        pattern?.route.shortName == routeName,
                                    orElse: () => null,
                                  );
                              final route = pattern?.route;
                              final routeColor =
                                  route?.color ??
                                  getRouteBackgroundColor(routeName);
                              final routeTextColor =
                                  route?.textColor ?? Colors.black;

                              return FilterChip(
                                label: Text(
                                  routeName,
                                  style: TextStyle(
                                    color: routeTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected:
                                    (selected) => _toggleRouteFilter(routeName),
                                backgroundColor: routeColor,
                                selectedColor: routeColor,
                                checkmarkColor: Colors.black,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Timetable content or empty state
            if (groupedDepartures.isEmpty && _timedPatterns.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No timetable data available.'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _fetchTimetable,
                        child: const Text('Load Timetable'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index.isOdd) {
                    return Container(
                      height: 1.5,
                      color: Theme.of(context).primaryColor.withOpacity(0.25),
                    );
                  }
                  final hourIndex = index ~/ 2;
                  final hour = sortedHours.elementAt(hourIndex);
                  final departures = groupedDepartures[hour]!;
                  return HourDeparturesWidget(
                    timedStops: departures,
                    hour: hour,
                  );
                }, childCount: sortedHours.length * 2 - 1),
              ),
          ],
        );
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.stop.mode ?? 'BUS';
    return Scaffold(
      backgroundColor: primary50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: primary500,
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  ),
                  Icon(iconForMode(mode), color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.stop.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    tooltip: 'Open in Maps',
                    onPressed: () async {
                      unawaited(
                        MapsLauncher.launchCoordinates(
                          widget.stop.lat,
                          widget.stop.lon,
                          widget.stop.name,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'Right now'), Tab(text: 'Timetable')],
              onTap: (index) {
                if (index == 1 &&
                    _timedPatterns.isEmpty &&
                    !_timetableLoading) {
                  _fetchTimetable();
                }
              },
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildRightNowTab(), _buildTimetableTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
