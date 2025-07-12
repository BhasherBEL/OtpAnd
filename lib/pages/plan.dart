import 'dart:async';
import 'package:flutter/material.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/pages/plan/journey_details_card.dart';
import 'package:otpand/pages/plan/auto_update_row.dart';
import 'package:otpand/pages/plan/plan_timeline.dart';
import 'package:otpand/utils.dart';
import 'package:otpand/utils/colors.dart';
import 'package:otpand/widgets/route_map.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otpand/blocs/plan/bloc.dart';
import 'package:otpand/blocs/plan/events.dart';
import 'package:otpand/blocs/plan/states.dart';
import 'package:otpand/blocs/plan/repository.dart';

class PlanPage extends StatelessWidget {
  final Plan plan;

  const PlanPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlanBloc(PlanRepository())..add(LoadPlan(plan)),
      child: const _PlanView(),
    );
  }
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
    if (widget.lastUpdate == null) return 'Never updated';
    final now = DateTime.now();
    final diff = now.difference(widget.lastUpdate!);
    if (diff.inSeconds < 10) return 'Just now';
    return '${displayTime(diff.inSeconds)} ago';
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

class _PlanView extends StatefulWidget {
  const _PlanView();

  @override
  State<_PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<_PlanView>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool fullHeight = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlanBloc, PlanState>(
      listener: (context, state) {
        if (state is PlanLoaded && state.updating) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
          _rotationController.reset();
        }
        if (state is PlanError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is! PlanLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return Scaffold(
          backgroundColor: primary50,
          body: SafeArea(
            child: NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                final newValue = notification.extent >= 1;
                if (newValue != fullHeight) {
                  setState(() {
                    fullHeight = newValue;
                  });
                }
                return false;
              },
              child: Stack(
                children: [
                  RouteMapWidget(plan: state.plan),
                  DraggableScrollableSheet(
                    initialChildSize: 0.55,
                    minChildSize: 0.16,
                    maxChildSize: 1.0,
                    snap: true,
                    snapSizes: const [0.16, 0.55, 1.0],
                    builder: (context, scrollController) {
                      return ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(fullHeight ? 0 : 18),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: ListView(
                            controller: scrollController,
                            children: [
                              JourneyDetailsCard(plan: state.plan),
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: AutoUpdateRow(
                                  autoUpdateEnabled: state.autoUpdateEnabled,
                                  updating: state.updating,
                                  lastUpdate: state.lastUpdate,
                                  rotationController: _rotationController,
                                ),
                              ),
                              PlanTimeline(plan: state.plan),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
