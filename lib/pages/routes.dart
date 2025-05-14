import 'package:flutter/material.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/pages/route.dart';
import 'package:otpand/api/plan.dart';
import 'package:otpand/widgets/smallroute.dart';

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
  bool isLoading = true;
  List<Plan> results = [];
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
      results.clear();
    });

    try {
      final plans = await submitQuery(
        fromLocation: widget.fromLocation,
        toLocation: widget.toLocation,
        selectedMode: widget.selectedMode,
        timeType: widget.timeType,
        selectedDateTime: widget.selectedDateTime,
      );
      setState(() {
        results = plans;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Journey Results")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMsg != null
                ? Center(
                  child: Text(errorMsg!, style: TextStyle(color: Colors.red)),
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
    );
  }
}
