import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/pages/routes.dart';
import 'package:otpand/widgets/datetime_picker.dart';
import 'package:otpand/widgets/searchbar.dart';
import 'package:otpand/utils/colors.dart';

class Journeys extends StatefulWidget {
  const Journeys({super.key});

  @override
  State<Journeys> createState() => _JourneysState();
}

class _JourneysState extends State<Journeys> {
  Location? fromLocation;
  Location? toLocation;
  DateTimePickerValue dateTime = DateTimePickerValue(
    mode: DateTimePickerMode.now,
    dateTime: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(statusBarColor: primary500),
      child: Scaffold(
        backgroundColor: primary50, // Background color
        body: SafeArea(
          child: SingleChildScrollView(
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
                              "Where do we go ?",
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
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 10,
                                      left: 10,
                                      right: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SearchBarWidget(
                                                initialValue:
                                                    fromLocation?.displayName,
                                                selectedLocation: fromLocation,
                                                hintText: "From",
                                                onLocationSelected: (location) {
                                                  setState(() {
                                                    fromLocation = location;
                                                  });
                                                },
                                              ),
                                              DottedLine(
                                                direction: Axis.horizontal,
                                                dashColor: Colors.grey,
                                              ),
                                              SearchBarWidget(
                                                initialValue:
                                                    toLocation?.displayName,
                                                selectedLocation: toLocation,
                                                hintText: "To",
                                                onLocationSelected: (location) {
                                                  setState(() {
                                                    toLocation = location;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        IconButton(
                                          icon: Icon(
                                            Icons.swap_vert,
                                            color: primary500,
                                            size: 40,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              final temp = fromLocation;
                                              fromLocation = toLocation;
                                              toLocation = temp;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Column(
                                      children: [
                                        DottedLine(
                                          direction: Axis.horizontal,
                                          dashColor: Colors.grey,
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: DateTimePicker(
                                                value: dateTime,
                                                onChanged: (value) {
                                                  setState(() {
                                                    dateTime = value;
                                                  });
                                                },
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: primary500.withOpacity(
                                                  0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: TextButton.icon(
                                                onPressed: () {},
                                                icon: const Icon(
                                                  Icons.settings,
                                                  size: 18,
                                                  color: primary500,
                                                ),
                                                label: const Text(
                                                  "Options",
                                                  style: TextStyle(
                                                    color: primary500,
                                                  ),
                                                ),
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                  ),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                      ),
                                      onPressed: () {
                                        if (fromLocation != null &&
                                            toLocation != null) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => RoutesPage(
                                                    fromLocation: fromLocation!,
                                                    toLocation: toLocation!,
                                                    selectedMode: "TRANSIT",
                                                    timeType:
                                                        dateTime.mode ==
                                                                DateTimePickerMode
                                                                    .now
                                                            ? "now"
                                                            : (dateTime.mode ==
                                                                    DateTimePickerMode
                                                                        .departure
                                                                ? "depart"
                                                                : "arrive"),
                                                    selectedDateTime:
                                                        dateTime.dateTime,
                                                  ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Please select both origin and destination.",
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text("Plan my journey"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
