import 'package:flutter/material.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/pages/route/leg_departure.dart';
import 'package:otpand/utils.dart';
import 'package:otpand/widgets/departure.dart';
import 'package:otpand/widgets/route_icon.dart';

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
        .where(
          (departure) => departure.realTime,
        )
        .toList();

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
                children: departuresList
                    .map((leg) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: LegDepartureWidget(leg: leg)))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
