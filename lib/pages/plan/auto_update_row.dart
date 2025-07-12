import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otpand/blocs/plan/bloc.dart';
import 'package:otpand/blocs/plan/events.dart';
import 'package:otpand/pages/plan/last_update_widget.dart';

class AutoUpdateRow extends StatelessWidget {
  final bool autoUpdateEnabled;
  final bool updating;
  final DateTime? lastUpdate;
  final AnimationController rotationController;

  const AutoUpdateRow({
    super.key,
    required this.autoUpdateEnabled,
    required this.updating,
    required this.lastUpdate,
    required this.rotationController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: updating ? rotationController.value * 6.28319 * 2 : 0,
              child: IconButton(
                icon: Icon(
                  autoUpdateEnabled
                      ? Icons.autorenew
                      : Icons.autorenew_outlined,
                  color: autoUpdateEnabled ? Colors.blue : Colors.grey,
                ),
                tooltip: autoUpdateEnabled
                    ? (updating ? 'Updating...' : 'Disable automatic update')
                    : 'Enable automatic update',
                onPressed: updating
                    ? null
                    : () => context.read<PlanBloc>().add(ToggleAutoUpdate()),
              ),
            );
          },
        ),
        if (autoUpdateEnabled)
          GestureDetector(
            onTap: updating
                ? null
                : () => context.read<PlanBloc>().add(const UpdateLegs()),
            child: LastUpdateWidget(
              lastUpdate: lastUpdate,
              updating: updating,
            ),
          ),
        if (!autoUpdateEnabled)
          TextButton(
            onPressed: updating
                ? null
                : () => context.read<PlanBloc>().add(ToggleAutoUpdate()),
            child: Text(
              'No live update',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ),
      ],
    );
  }
}
