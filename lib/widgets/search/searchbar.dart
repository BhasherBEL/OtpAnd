import 'dart:async';

import 'package:flutter/material.dart';
import 'package:otpand/objects/location.dart';
import 'package:otpand/widgets/search/searchmodal.dart';

class SearchBarWidget extends StatefulWidget {
  final String? initialValue;
  final Location? selectedLocation;
  final void Function(Location?) onLocationSelected;
  final String hintText;

  const SearchBarWidget({
    super.key,
    this.initialValue,
    this.selectedLocation,
    required this.onLocationSelected,
    this.hintText = 'Search for a location...',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  String? _selectedText;

  @override
  void initState() {
    super.initState();
    _selectedText = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _selectedText = widget.initialValue;
      });
    }
  }

  Future<void> _openSearchModal() async {
    final result = await SearchModal.show(context);
    if (result != null) {
      setState(() {
        _selectedText = result.displayName;
      });
      widget.onLocationSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _openSearchModal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedText ?? widget.hintText,
                    style: TextStyle(
                      color:
                          _selectedText == null
                              ? Colors.grey[500]
                              : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.selectedLocation != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Selected: ${widget.selectedLocation!.displayName}',
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
