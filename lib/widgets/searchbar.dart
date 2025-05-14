import 'package:flutter/material.dart';
import 'package:otpand/api.dart';
import 'package:otpand/objs.dart';

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
    this.hintText = "Search for a location...",
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _lastSearchedText = '';
  Location? _selectedLocation;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        if (_controller.text.trim() != _lastSearchedText.trim()) {
          _search();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue ?? '';
      // Do not update _selectedLocation here; rely on widget.selectedLocation for display.
      setState(() {
        if (widget.initialValue == null || widget.initialValue!.isEmpty) {
          _selectedLocation = null;
        }
      });
    }
  }

  Future<void> _search() async {
    final trimmedText = _controller.text.trim();
    _lastSearchedText = trimmedText;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final location = await geoCodeNominatimApi(trimmedText);
      if (location != null) {
        setState(() {
          _selectedLocation = location;
          _controller.text = location.displayName;
          _isLoading = false;
        });
        widget.onLocationSelected(location);
      } else {
        setState(() {
          _error = "No location found.";
          _isLoading = false;
        });
        widget.onLocationSelected(null);
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _isLoading = false;
      });
      widget.onLocationSelected(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            isDense: true,
            labelText: widget.hintText,
            border: InputBorder.none,
            suffixIcon:
                _isLoading
                    ? Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : IconButton(icon: Icon(Icons.search), onPressed: _search),
            errorText: _error,
          ),
          onSubmitted: (_) => _search(),
        ),
        if (widget.selectedLocation != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              "Selected: ${widget.selectedLocation!.displayName}",
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
