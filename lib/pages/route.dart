import 'dart:async';
import 'package:flutter/material.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/utils.dart';
import 'package:otpand/utils/colors.dart';
import 'package:otpand/widgets/routeIcon.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:otpand/widgets/intermediateStops.dart';
import 'package:otpand/pages/trip.dart';
import 'package:otpand/pages/stop.dart';
import 'package:otpand/api/plan.dart';

class RoutePage extends StatefulWidget {
  final Plan plan;

  const RoutePage({super.key, required this.plan});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class LastUpdateWidget extends StatefulWidget {
  final DateTime? lastUpdate;
  final bool updating;

  const LastUpdateWidget({
    super.key,
    required this.lastUpdate,
    required this.updating,
  });

  @override
  State<LastUpdateWidget> createState() => _LastUpdateWidgetState();
}

class _LastUpdateWidgetState extends State<LastUpdateWidget> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _lastUpdateText() {
    if (widget.lastUpdate == null) return "Never updated";
    final now = DateTime.now();
    final diff = now.difference(widget.lastUpdate!);
    if (diff.inSeconds < 10) return "Just now";
    return "${displayTime(diff.inSeconds)} ago";
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _lastUpdateText(),
      style: TextStyle(
        color: widget.updating ? Colors.grey.shade500 : Colors.blue.shade300,
        fontWeight: FontWeight.w500,
        decoration: widget.updating ? null : TextDecoration.underline,
        decorationColor: Colors.blue.shade300,
      ),
    );
  }
}

class _RoutePageState extends State<RoutePage>
    with SingleTickerProviderStateMixin {
  late List<Leg> _legs;
  DateTime? _lastUpdate;
  bool _updating = false;
  Timer? _timer;
  bool _autoUpdateEnabled = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _legs = List<Leg>.from(widget.plan.legs);
    _lastUpdate = DateTime.now();
    _autoUpdateEnabled = _legs.any((leg) => leg.realTime == true);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (_autoUpdateEnabled) {
      _startAutoUpdate();
    }
  }

  void _startAutoUpdate() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateLegs();
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
      } else {
        _stopAutoUpdate();
      }
    });
  }

  Future<void> _updateLegs() async {
    setState(() {
      _updating = true;
    });
    _rotationController.repeat();

    var updatedLegs = _legs;

    try {
      updatedLegs = await Future.wait(
        _legs.map((leg) async {
          if (leg.id != null) {
            final updated = await fetchLegById(leg.id!);
            return updated ?? leg;
          }
          return leg;
        }),
      );
    } catch (e) {
      setState(() {
        _updating = false;
      });
      _rotationController.stop();
      _rotationController.reset();
      return;
    }

    setState(() {
      _legs = updatedLegs;
      _lastUpdate = DateTime.now();
      _updating = false;
    });
    _rotationController.stop();
    _rotationController.reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RoutePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.plan != oldWidget.plan) {
      _legs = List<Leg>.from(widget.plan.legs);
      _lastUpdate = DateTime.now();
      _autoUpdateEnabled = _legs.any((leg) => leg.realTime == true);
      if (_autoUpdateEnabled) {
        _startAutoUpdate();
      } else {
        _stopAutoUpdate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final legs = _legs;

    return Scaffold(
      backgroundColor: primary50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 180,
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
                            "Journey Details",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.hardEdge,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          legs.first.from.name,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_right_alt,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              legs.last.to.name,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        formatTime(
                                              legs
                                                      .first
                                                      .from
                                                      .departure
                                                      ?.estimated
                                                      ?.time ??
                                                  legs
                                                      .first
                                                      .from
                                                      .departure
                                                      ?.scheduledTime,
                                            ) ??
                                            '',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Icon(
                                        Icons.arrow_downward,
                                        size: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formatTime(
                                              legs
                                                      .last
                                                      .to
                                                      .arrival
                                                      ?.estimated
                                                      ?.time ??
                                                  legs
                                                      .last
                                                      .to
                                                      .arrival
                                                      ?.scheduledTime,
                                            ) ??
                                            '',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle:
                              _updating
                                  ? _rotationController.value * 6.28319 * 2
                                  : 0,
                          child: IconButton(
                            icon: Icon(
                              _autoUpdateEnabled
                                  ? Icons.autorenew
                                  : Icons.autorenew_outlined,
                              color:
                                  _autoUpdateEnabled
                                      ? Colors.blue
                                      : Colors.grey,
                            ),
                            tooltip:
                                _autoUpdateEnabled
                                    ? (_updating
                                        ? "Updating..."
                                        : "Disable automatic update")
                                    : "Enable automatic update",
                            onPressed: _updating ? null : _toggleAutoUpdate,
                          ),
                        );
                      },
                    ),
                    if (_autoUpdateEnabled)
                      GestureDetector(
                        onTap: _updating ? null : _updateLegs,
                        child: LastUpdateWidget(
                          lastUpdate: _lastUpdate,
                          updating: _updating,
                        ),
                      ),
                    if (!_autoUpdateEnabled)
                      TextButton(
                        onPressed: _updating ? null : _toggleAutoUpdate,
                        child: Text(
                          "No live update",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 32),
                child: FixedTimeline.tileBuilder(
                  theme: TimelineThemeData(
                    nodePosition: 0,
                    color: Colors.blueAccent,
                    indicatorTheme: IndicatorThemeData(size: 26, position: 0),
                    connectorTheme: ConnectorThemeData(
                      thickness: 2.0,
                      color: Colors.blueAccent,
                    ),
                  ),
                  builder: TimelineTileBuilder.connected(
                    connectionDirection: ConnectionDirection.before,
                    itemCount: legs.length + 1,
                    contentsBuilder: (context, index) {
                      final leg = index < legs.length ? legs[index] : null;
                      final previousLeg = index > 0 ? legs[index - 1] : null;

                      final place = leg?.from ?? previousLeg!.to;

                      final departureTimeRt =
                          leg?.from.departure?.estimated?.time;
                      final departureTimeTheory =
                          leg?.from.departure?.scheduledTime;
                      final departureTime =
                          departureTimeRt ?? departureTimeTheory;
                      final departureDelayed =
                          departureTimeRt != null &&
                          departureTimeRt != departureTimeTheory;

                      final arrivalTimeRt =
                          previousLeg?.to.arrival?.estimated?.time;
                      final arrivalTimeTheory =
                          previousLeg?.to.arrival?.scheduledTime;
                      final arrivalTime = arrivalTimeRt ?? arrivalTimeTheory;
                      final arrivalDelayed =
                          arrivalTimeRt != null &&
                          arrivalTimeRt != arrivalTimeTheory;

                      final transferTime =
                          arrivalTime != null
                              ? parseTime(
                                departureTime,
                              )?.difference(parseTime(arrivalTime)!).inSeconds
                              : null;
                      final hasTransfer =
                          transferTime != null && transferTime > 0;

                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      (leg?.transitLeg == true ||
                                              (leg == null &&
                                                  previousLeg?.transitLeg ==
                                                      true))
                                          ? GestureDetector(
                                            onTap: () {
                                              final stop =
                                                  leg?.from ?? previousLeg?.to;
                                              if (place.stop != null) {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) => StopPage(
                                                          stop: place.stop!,
                                                        ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Text(
                                              place.name,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor: Colors.grey,
                                              ),
                                            ),
                                          )
                                          : Text(
                                            place.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                ),
                                if (hasTransfer)
                                  Text(
                                    displayTime(transferTime),
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (hasTransfer ||
                                        leg == null ||
                                        previousLeg != null &&
                                            previousLeg.transitLeg)
                                      Row(
                                        children: [
                                          if (arrivalDelayed)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 4,
                                              ),
                                              child: Text(
                                                formatTime(arrivalTimeRt)!,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            formatTime(arrivalTimeTheory) ??
                                                '??:??',
                                            style: TextStyle(
                                              color:
                                                  arrivalTimeRt == null
                                                      ? Colors.grey.shade700
                                                      : Colors.green,
                                              decoration:
                                                  arrivalDelayed
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (hasTransfer)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: Icon(
                                          Icons.arrow_downward,
                                          size: 12,
                                        ),
                                      ),
                                    if (hasTransfer ||
                                        leg != null && leg.transitLeg ||
                                        previousLeg == null)
                                      Row(
                                        children: [
                                          if (departureDelayed)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 4,
                                              ),
                                              child: Text(
                                                formatTime(departureTimeRt)!,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            formatTime(departureTimeTheory) ??
                                                '??:??',
                                            style: TextStyle(
                                              color:
                                                  departureTimeRt == null
                                                      ? Colors.grey.shade700
                                                      : Colors.green,
                                              decoration:
                                                  departureDelayed
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            if (leg != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap:
                                          leg.trip != null &&
                                                  leg.serviceDate != null
                                              ? () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) => TripPage(
                                                          trip: leg.trip!,
                                                          serviceDate:
                                                              leg.serviceDate!,
                                                        ),
                                                  ),
                                                );
                                              }
                                              : null,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          if (leg.route != null)
                                            RouteIconWidget(route: leg.route!),
                                          Expanded(
                                            child: Text(
                                              leg.transitLeg
                                                  ? leg.headsign ??
                                                      leg.route?.longName ??
                                                      'Unknown'
                                                  : '${displayDistance(leg.distance)} - ${displayTime(leg.duration)}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                decoration:
                                                    leg.trip != null
                                                        ? TextDecoration
                                                            .underline
                                                        : null,
                                                decorationColor: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (leg.otherDepartures.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          'Also at ${leg.otherDeparturesText}',
                                        ),
                                      ),
                                    if (leg.transitLeg)
                                      IntermediateStopsWidget(
                                        stops: leg.intermediateStops,
                                        leg: leg,
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    indicatorBuilder: (context, index) {
                      if (index == 0) {
                        return const DotIndicator(
                          size: 24,
                          color: Colors.green,
                          child: Icon(
                            Icons.location_pin,
                            color: Colors.white,
                            size: 16,
                          ),
                        );
                      } else if (index == legs.length) {
                        return const DotIndicator(
                          size: 24,
                          color: Colors.red,
                          child: Icon(
                            Icons.flag,
                            color: Colors.white,
                            size: 16,
                          ),
                        );
                      } else {
                        return const OutlinedDotIndicator(
                          size: 20,
                          color: Colors.blue,
                          backgroundColor: Colors.white,
                          borderWidth: 2.0,
                        );
                      }
                    },
                    connectorBuilder: (context, index, type) {
                      if (index == 0) {
                        return null;
                      }
                      return const SolidLineConnector();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
