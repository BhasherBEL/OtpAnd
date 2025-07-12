import 'dart:async';
import 'package:flutter/material.dart';
import 'package:otpand/utils.dart';

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

