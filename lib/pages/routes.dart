import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/pages/route.dart';
import 'package:otpand/api/plan.dart';
import 'package:otpand/utils/colors.dart';
import 'package:otpand/widgets/smallroute.dart';
import 'package:otpand/widgets/searchbar.dart';
import 'package:otpand/widgets/datetime_picker.dart';
import 'package:dotted_line/dotted_line.dart';

class RoutesPage extends StatefulWidget {
  final Location fromLocation;
  final Location toLocation;
  final String selectedMode;
  final String timeType;
  final DateTime? selectedDateTime;

  const RoutesPage({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    required this.selectedMode,
    required this.timeType,
    required this.selectedDateTime,
  });

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  late Location? fromLocation;
  late Location? toLocation;
  late String selectedMode;
  late String timeType;
  late DateTime? selectedDateTime;

  bool isLoading = true;
  List<Plan> results = [];
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    fromLocation = widget.fromLocation;
    toLocation = widget.toLocation;
    selectedMode = widget.selectedMode;
    timeType = widget.timeType;
    selectedDateTime = widget.selectedDateTime;
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    if (fromLocation == null || toLocation == null) return;
    setState(() {
      isLoading = true;
      errorMsg = null;
      results.clear();
    });

    try {
      final plans = await submitQuery(
        fromLocation: fromLocation!,
        toLocation: toLocation!,
        selectedMode: selectedMode,
        timeType: timeType,
        selectedDateTime: selectedDateTime,
      );
      setState(() {
        results = plans;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        print(errorMsg);
        isLoading = false;
      });
    }
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
      timeType =
          value.mode == DateTimePickerMode.now
              ? "now"
              : (value.mode == DateTimePickerMode.departure
                  ? "start"
                  : "arrive");
      selectedDateTime = value.dateTime;
    });
    if (fromLocation != null && toLocation != null) {
      _fetchPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(statusBarColor: primary500),
      child: Scaffold(
        backgroundColor: primary50,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
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
                            "How do we get there?",
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
                              padding: const EdgeInsets.only(
                                top: 10,
                                left: 10,
                                right: 10,
                                bottom: 10,
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
                                          onLocationSelected:
                                              _onFromLocationChanged,
                                        ),
                                        DottedLine(
                                          direction: Axis.horizontal,
                                          dashColor: Colors.grey,
                                        ),
                                        SearchBarWidget(
                                          initialValue: toLocation?.displayName,
                                          selectedLocation: toLocation,
                                          hintText: "To",
                                          onLocationSelected:
                                              _onToLocationChanged,
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
                                    onPressed: _onSwap,
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
              // DATETIME PICKER
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: DateTimePicker(
                  value: DateTimePickerValue(
                    mode:
                        timeType == "now"
                            ? DateTimePickerMode.now
                            : (timeType == "start"
                                ? DateTimePickerMode.departure
                                : DateTimePickerMode.arrival),
                    dateTime: selectedDateTime ?? DateTime.now(),
                  ),
                  onChanged: _onDateTimeChanged,
                ),
              ),
              // RESULTS
              Expanded(
                child:
                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : errorMsg != null
                        ? Center(
                          child: Text(
                            errorMsg!,
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                        : results.isEmpty
                        ? Center(child: Text("No plans found."))
                        : ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (ctx, idx) {
                            final plan = results[idx];
                            return SmallRoute(
                              plan: plan,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RoutePage(plan: plan),
                                  ),
                                );
                              },
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
