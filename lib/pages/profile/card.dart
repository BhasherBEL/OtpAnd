import 'package:flutter/material.dart';

class ProfileCardWidget extends StatefulWidget {
  final String title;
  final String? description;
  final bool initialState;
  final ValueChanged<bool>? onStateChanged;
  final List<Widget>? children;
  final bool hasBorder;

  const ProfileCardWidget({
    super.key,
    required this.title,
    this.description,
    required this.initialState,
    this.onStateChanged,
    required this.children,
    this.hasBorder = false,
  });

  @override
  State<ProfileCardWidget> createState() => _ProfileCardWidgetState();
}

class _ProfileCardWidgetState extends State<ProfileCardWidget> {
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(widget.title),
          subtitle:
              widget.description != null ? Text(widget.description!) : null,
          value: widget.initialState,
          onChanged: (bool value) {
            setState(() {
              isExpanded = value;
            });
            if (widget.onStateChanged != null) {
              widget.onStateChanged!(value);
            }
          },
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        if (widget.children != null && isExpanded)
          Container(
            decoration: BoxDecoration(
              border: widget.hasBorder
                  ? Border(
                      left: BorderSide(
                        color: Colors.grey,
                        width: 2.0,
                      ),
                    )
                  : null,
            ),
            padding: widget.hasBorder ? EdgeInsets.only(left: 16) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children!,
            ),
          )
      ],
    );
  }
}
