import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otpand/objects/profile.dart';
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
  final Profile profile;
  final String timeType;
  final DateTime? selectedDateTime;

  const RoutesPage({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    required this.profile,
    required this.timeType,
    required this.selectedDateTime,
  });

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  late Location? fromLocation;
  late Location? toLocation;
  late Profile profile;
  late String timeType;
  late DateTime? selectedDateTime;

  bool isLoading = true;
  bool isPaginatingForward = false;
  bool isPaginatingBackward = false;
  List<Plan> results = [];
  String? errorMsg;

  String? startCursor;
  String? endCursor;
  bool hasNextPage = false;
  bool hasPreviousPage = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fromLocation = widget.fromLocation;
    toLocation = widget.toLocation;
    profile = widget.profile;
    timeType = widget.timeType;
    selectedDateTime = widget.selectedDateTime;
    _fetchPlans();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlans({String? after, String? before}) async {
    if (fromLocation == null || toLocation == null) return;

    if (after == null && before == null) {
      setState(() {
        isLoading = true;
        isPaginatingForward = false;
        isPaginatingBackward = false;
        errorMsg = null;
        results.clear();
      });
    } else if (after != null) {
      setState(() {
        isPaginatingForward = true;
        isPaginatingBackward = false;
        errorMsg = null;
      });
    } else if (before != null) {
      setState(() {
        isPaginatingBackward = true;
        isPaginatingForward = false;
        errorMsg = null;
      });
    }

    try {
      final resp = await submitQuery(
        fromLocation: fromLocation!,
        toLocation: toLocation!,
        profile: profile,
        timeType: timeType,
        selectedDateTime: selectedDateTime,
        after: after,
        before: before,
        first: (after != null || before == null) ? 5 : null,
        last: (before != null) ? 5 : null,
      );
      setState(() {
        final newPlans = resp["plans"] as List<Plan>;

        newPlans.sort((a, b) {
          final aTime = DateTime.tryParse(a.start) ?? DateTime.now();
          final bTime = DateTime.tryParse(b.start) ?? DateTime.now();
          return aTime.compareTo(bTime);
        });

        if (after != null) {
          results.addAll(newPlans.where((plan) => !results.contains(plan)));
        } else if (before != null) {
          results.insertAll(
            0,
            newPlans.where((plan) => !results.contains(plan)),
          );
        } else {
          results = newPlans;
        }

        results.sort((a, b) {
          final aTime = DateTime.tryParse(a.start) ?? DateTime.now();
          final bTime = DateTime.tryParse(b.start) ?? DateTime.now();
          return aTime.compareTo(bTime);
        });

        isLoading = false;
        isPaginatingForward = false;
        isPaginatingBackward = false;
        final pageInfo = resp["pageInfo"];
        startCursor = pageInfo?["startCursor"];
        endCursor = pageInfo?["endCursor"];
        hasNextPage = pageInfo?["hasNextPage"] ?? false;
        hasPreviousPage = pageInfo?["hasPreviousPage"] ?? false;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        print(errorMsg);
        isLoading = false;
        isPaginatingForward = false;
        isPaginatingBackward = false;
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

  Widget _buildPaginationButton({
    required String text,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: isLoading ? null : onPressed,
            child: Text(text),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchBarWidget(
                      initialValue: fromLocation?.displayName,
                      selectedLocation: fromLocation,
                      hintText: "From",
                      onLocationSelected: _onFromLocationChanged,
                    ),
                    DottedLine(
                      direction: Axis.horizontal,
                      dashColor: Colors.grey,
                    ),
                    SearchBarWidget(
                      initialValue: toLocation?.displayName,
                      selectedLocation: toLocation,
                      hintText: "To",
                      onLocationSelected: _onToLocationChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.swap_vert, color: primary500, size: 40),
                onPressed: _onSwap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    int itemCount =
        results.length + (hasPreviousPage ? 1 : 0) + (hasNextPage ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (ctx, idx) {
        int offset = hasPreviousPage ? 1 : 0;

        if (hasPreviousPage && idx == 0) {
          return _buildPaginationButton(
            text: "Show earlier trips",
            isLoading: isPaginatingBackward,
            onPressed:
                (isPaginatingBackward || startCursor == null)
                    ? null
                    : () => _fetchPlans(before: startCursor),
          );
        }

        if (hasNextPage && idx == results.length + offset) {
          return _buildPaginationButton(
            text: "Show later trips",
            isLoading: isPaginatingForward,
            onPressed:
                (isPaginatingForward || endCursor == null)
                    ? null
                    : () => _fetchPlans(after: endCursor),
          );
        }

        final plan = results[idx - offset];
        return SmallRoute(
          plan: plan,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => RoutePage(plan: plan)));
          },
        );
      },
    );
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
                        _buildSearchCard(),
                      ],
                    ),
                  ),
                ],
              ),
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
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (isLoading && results.isEmpty) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (errorMsg != null && results.isEmpty) {
                      return Center(
                        child: Text(
                          errorMsg!,
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    if (results.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 150),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasPreviousPage)
                              _buildPaginationButton(
                                text: "Show earlier trips",
                                isLoading: isPaginatingBackward,
                                onPressed:
                                    (isPaginatingBackward ||
                                            startCursor == null)
                                        ? null
                                        : () =>
                                            _fetchPlans(before: startCursor),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: Text("No plans found."),
                            ),
                            if (hasNextPage)
                              _buildPaginationButton(
                                text: "Show later trips",
                                isLoading: isPaginatingForward,
                                onPressed:
                                    (isPaginatingForward || endCursor == null)
                                        ? null
                                        : () => _fetchPlans(after: endCursor),
                              ),
                          ],
                        ),
                      );
                    }
                    return _buildListView();
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
