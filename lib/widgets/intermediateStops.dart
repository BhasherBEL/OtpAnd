import 'package:flutter/material.dart';
import 'package:otpand/objects/timedStop.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/utils.dart';
import 'package:otpand/pages/stop.dart';

class IntermediateStopsWidget extends StatefulWidget {
  final List<TimedStop> stops;
  final Leg? leg;

  const IntermediateStopsWidget({super.key, required this.stops, this.leg});

  @override
  State<IntermediateStopsWidget> createState() =>
      _IntermediateStopsWidgetState();
}

class _IntermediateStopsWidgetState extends State<IntermediateStopsWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final List<TimedStop> stopsWithStop =
        widget.stops
            .where(
              (s) =>
                  s.dropoffType != null &&
                      s.dropoffType != PickupDropoffType.NONE ||
                  s.pickupType != null &&
                      s.pickupType != PickupDropoffType.NONE,
            )
            .toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              '${stopsWithStop.length} stop${stopsWithStop.length == 1 ? '' : 's'}${widget.leg != null ? ' (${displayTime(widget.leg!.duration)})' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap:
                stopsWithStop.isNotEmpty
                    ? () => setState(() => _expanded = !_expanded)
                    : null,
            trailing:
                stopsWithStop.isNotEmpty
                    ? Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.blueAccent,
                    )
                    : null,
          ),
          if (_expanded && stopsWithStop.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              child: Column(
                children: List.generate(stopsWithStop.length, (i) {
                  final stop = stopsWithStop[i];

                  final arrivalTimeRt = stop.arrival.estimated?.time;
                  final arrivalTimeTheory = stop.arrival.scheduledTime;
                  final arrivalDelayed =
                      arrivalTimeRt != null &&
                      arrivalTimeRt != arrivalTimeTheory;

                  final departureTimeRt = stop.departure.estimated?.time;
                  final departureTimeTheory = stop.departure.scheduledTime;
                  final departureDelayed =
                      departureTimeRt != null &&
                      departureTimeRt != departureTimeTheory;

                  final pickupDropoffWarns = [];

                  if (stop.pickupType != null) {
                    switch (stop.pickupType!) {
                      case PickupDropoffType.NONE:
                        pickupDropoffWarns.add('no pickup');
                        break;
                      case PickupDropoffType.COORDINATE_WITH_DRIVER:
                      case PickupDropoffType.CALL_AGENCY:
                        pickupDropoffWarns.add('pickup on request');
                        break;
                      case PickupDropoffType.SCHEDULED:
                        break;
                    }
                  }
                  if (stop.dropoffType != null) {
                    switch (stop.dropoffType!) {
                      case PickupDropoffType.NONE:
                        pickupDropoffWarns.add('no dropoff');
                        break;
                      case PickupDropoffType.COORDINATE_WITH_DRIVER:
                      case PickupDropoffType.CALL_AGENCY:
                        pickupDropoffWarns.add('dropoff on request');
                        break;
                      case PickupDropoffType.SCHEDULED:
                        break;
                    }
                  }

                  final pickupDropoffText =
                      pickupDropoffWarns.isNotEmpty
                          ? pickupDropoffWarns.join(', ')
                          : null;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stop_circle,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => StopPage(stop: stop.stop),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  stop.stop.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: Colors.black,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.grey,
                                  ),
                                ),
                                if (pickupDropoffText != null)
                                  Expanded(
                                    child: Text(
                                      ' ($pickupDropoffText)',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                if (arrivalDelayed)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      formatTime(arrivalTimeRt)!,
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                Text(
                                  formatTime(arrivalTimeTheory) ?? '??:??',
                                  style: TextStyle(
                                    color:
                                        arrivalTimeRt == null
                                            ? Colors.grey.shade700
                                            : Colors.green,
                                    decoration:
                                        arrivalDelayed
                                            ? TextDecoration.lineThrough
                                            : null,
                                  ),
                                ),
                              ],
                            ),
                            if (arrivalTimeRt != departureTimeRt ||
                                arrivalTimeTheory != departureTimeTheory)
                              Row(
                                children: [
                                  if (departureDelayed)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        formatTime(departureTimeRt)!,
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  Text(
                                    formatTime(departureTimeTheory) ?? '??:??',
                                    style: TextStyle(
                                      color:
                                          departureTimeRt == null
                                              ? Colors.grey.shade700
                                              : Colors.green,
                                      decoration:
                                          departureDelayed
                                              ? TextDecoration.lineThrough
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
