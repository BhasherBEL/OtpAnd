import 'package:flutter/material.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/pages/plan/leg_departure.dart';

class OtherDeparturesWidget extends StatefulWidget {
  const OtherDeparturesWidget({
    super.key,
    required this.leg,
  });

  final Leg leg;

  @override
  State<OtherDeparturesWidget> createState() => _OtherDeparturesWidgetState();
}

class _OtherDeparturesWidgetState extends State<OtherDeparturesWidget> {
  @override
  Widget build(BuildContext context) {
    final departuresList = widget.leg.otherDepartures
        .where((leg) =>
            leg.from.departure?.realDateTime != null &&
            leg.to.arrival?.realDateTime != null)
        .toList()
      ..add(widget.leg)
      ..sort((a, b) {
        final aTime = a.from.departure!.realDateTime!;
        final bTime = b.from.departure!.realDateTime!;

        return aTime.compareTo(bTime);
      });
    final summaryText = widget.leg.frequency != null
        ? 'Every ${widget.leg.frequency} minutes'
        : 'Other Departures';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        title: Text(summaryText),
        subtitle: Text(
          widget.leg.frequency != null
              ? '(${widget.leg.otherDeparturesText(short: true)})'
              : 'Also at ${widget.leg.otherDeparturesText()}',
        ),
        children: [
          if (departuresList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('No other departures.'),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: departuresList.asMap().entries.map((e) {
                  final bool isSlower = departuresList.sublist(e.key + 1).any(
                      (leg) =>
                          leg.to.arrival?.realDateTime != null &&
                          e.value.to.arrival?.realDateTime != null &&
                          e.value.to.arrival!.realDateTime!
                              .isAfter(leg.to.arrival!.realDateTime!));
                  return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: LegDepartureWidget(
                        leg: e.value,
                        isCurrent: e.value.id == widget.leg.id,
                        isSlower: isSlower,
                      ));
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
