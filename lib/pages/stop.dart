// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:otpand/objects/stop.dart';

import 'package:otpand/objects/timedStop.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  List<TimedStop> _departures = [];
  bool _loading = false;
  bool _autoUpdateEnabled = false;
  DateTime? _lastUpdate;
  Timer? _timer;
  late AnimationController _rotationController;
  bool _isInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print(widget.stop.gtfsId);
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
    super.dispose();
  }

  void _startAutoUpdate() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_isInForeground) {
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
    _rotationController.repeat();
    try {
      final departures = await stop_api.fetchNextDepartures(widget.stop);
      setState(() {
        _departures = departures;
        _lastUpdate = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _departures = [];
        _loading = false;
      });
    }
    _rotationController.stop();
    _rotationController.reset();
  }

  String _lastUpdateText() {
    if (_lastUpdate == null) return "Never updated";
    final now = DateTime.now();
    final diff = now.difference(_lastUpdate!);
    if (diff.inSeconds < 10) return "Just now";
    return "${displayTime(diff.inSeconds)} ago";
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isInForeground = state == AppLifecycleState.resumed;
    });
    // Optionally, fetch departures when returning to foreground
    if (_isInForeground && _autoUpdateEnabled) {
      _fetchDepartures();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.stop.mode ?? "BUS";
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
                      await MapsLauncher.launchCoordinates(
                        widget.stop.lat,
                        widget.stop.lon,
                        widget.stop.name,
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle:
                            _loading
                                ? _rotationController.value * 6.28319 * 2
                                : 0,
                        child: IconButton(
                          icon: Icon(
                            _autoUpdateEnabled
                                ? Icons.autorenew
                                : Icons.autorenew_outlined,
                            color:
                                _autoUpdateEnabled ? Colors.blue : Colors.grey,
                          ),
                          tooltip:
                              _autoUpdateEnabled
                                  ? (_loading
                                      ? "Updating..."
                                      : "Disable automatic update")
                                  : "Enable automatic update",
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
                          decoration:
                              _loading ? null : TextDecoration.underline,
                          decorationColor: Colors.blue.shade300,
                        ),
                      ),
                    ),
                  if (!_autoUpdateEnabled)
                    TextButton(
                      onPressed: _loading ? null : _toggleAutoUpdate,
                      child: Text(
                        "No live update",
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
        ),
      ),
    );
  }
}
