import 'package:flutter/material.dart';
import 'package:otpand/api.dart';
import 'package:otpand/objs.dart';

class SearchBarWidget extends StatefulWidget {
  final String? initialValue;
  final void Function(Location?) onLocationSelected;
  final String hintText;

  const SearchBarWidget({
    super.key,
    this.initialValue,
    required this.onLocationSelected,
    this.hintText = "Search for a location...",
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  Location? _selectedLocation;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final location = await geoCodeNominatimApi(_controller.text.trim());
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
          decoration: InputDecoration(
            labelText: widget.hintText,
            suffixIcon:
                _isLoading
                    ? Padding(
                      padding: const EdgeInsets.all(12.0),
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
        if (_selectedLocation != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              "Selected: ${_selectedLocation!.displayName}",
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
