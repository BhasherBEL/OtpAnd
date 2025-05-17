import 'package:flutter/material.dart';
import 'package:otpand/objects/timedStop.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/utils.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              '${widget.stops.length} stop${widget.stops.length == 1 ? '' : 's'}${widget.leg != null ? ' (${displayTime(widget.leg!.duration)})' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap:
                widget.stops.isNotEmpty
                    ? () => setState(() => _expanded = !_expanded)
                    : null,
            trailing:
                widget.stops.isNotEmpty
                    ? Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.blueAccent,
                    )
                    : null,
          ),
          if (_expanded && widget.stops.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              child: Column(
                children: List.generate(widget.stops.length, (i) {
                  final stop = widget.stops[i];

                  final arrivalTimeRt = stop.arrival.estimated?.time;
                  final arrivalTimeTheory = stop.arrival.scheduledTime;
                  final arrivalDelayed =
                      arrivalTimeRt != null &&
                      arrivalTimeRt != arrivalTimeTheory;

                  final departureTimeRt = stop.departure?.estimated?.time;
                  final departureTimeTheory = stop.departure?.scheduledTime;
                  final departureDelayed =
                      departureTimeRt != null &&
                      departureTimeRt != departureTimeTheory;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.stop_circle,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stop.stop.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Column(
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
