import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:otpand/objects/stop.dart';
import 'package:intl/intl.dart';

import 'package:otpand/objects/timed_stop.dart';
import 'package:otpand/objects/timed_pattern.dart';
import 'package:otpand/api/stop.dart' as stop_api;
import 'package:otpand/utils.dart';
import 'package:otpand/utils/colors.dart';
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

  // Right now tab
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

      // Group patterns by route and headsign
      final Map<String, TimedPattern> mergedPatterns = {};

      for (final pattern in timedPatterns) {
        // Create a unique key based on route gtfsId and headsign
        final key = '${pattern.route.gtfsId}_${pattern.headSign ?? ''}';

        if (mergedPatterns.containsKey(key)) {
          // Merge with existing pattern by combining timedStops
          final existing = mergedPatterns[key]!;
          final allTimedStops = [...existing.timedStops, ...pattern.timedStops];

          // Sort by departure time
          allTimedStops.sort((a, b) {
            final aTime = a.departure.scheduledTime;
            final bTime = b.departure.scheduledTime;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return aTime.compareTo(bTime);
          });

          mergedPatterns[key] = TimedPattern(
            timedStops: allTimedStops,
            headSign: existing.headSign,
            route: existing.route,
          );
        } else {
          // Add new pattern
          mergedPatterns[key] = pattern;
        }
      }

      setState(() {
        _timedPatterns = mergedPatterns.values.toList();
        _timetableLoading = false;
      });
    } on Exception catch (e, s) {
      debugPrintStack(stackTrace: s, label: 'Error fetching timetable: $e');
      setState(() {
        _timedPatterns = [];
        _timetableLoading = false;
      });
    }
  }

  String _lastUpdateText() {
    if (_lastUpdate == null) return 'Never updated';
    final now = DateTime.now();
    final diff = now.difference(_lastUpdate!);
    if (diff.inSeconds < 10) return 'Just now';
    return '${displayTime(diff.inSeconds)} ago';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isInForeground = state == AppLifecycleState.resumed;
    });
    // Optionally, fetch departures when returning to foreground
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
    return Column(
      children: [
        // Day selector
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null && date != _selectedDate) {
                    setState(() {
                      _selectedDate = date;
                      _timedPatterns = [];
                    });
                    unawaited(_fetchTimetable());
                  }
                },
                child: const Text('Change Date'),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _timetableLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _timedPatterns.isEmpty
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
                  : ListView.builder(
                    itemCount: _timedPatterns.length,
                    itemBuilder: (context, index) {
                      final pattern = _timedPatterns[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: pattern.route.color ?? Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  pattern.route.shortName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pattern.headSign ?? pattern.route.longName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    pattern.timedStops.map((timedStop) {
                                      final departureTime =
                                          timedStop.departure.scheduledTime;
                                      if (departureTime != null) {
                                        final time = DateTime.parse(
                                          departureTime,
                                        );
                                        final timeStr = DateFormat(
                                          'HH:mm',
                                        ).format(time);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            timeStr,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
