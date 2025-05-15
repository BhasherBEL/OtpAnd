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
  bool _isLoading = false;
  String? _error;

  List<Location> _suggestions = [];
  bool _suggestionsLoading = false;

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
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        if (_controller.text.trim() != _lastSearchedText.trim()) {
          _search();
        }
      }
    });
  }

  void _onTextChanged() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _suggestions = [];
        _suggestionsLoading = false;
      });
      return;
    }
    setState(() {
      _suggestionsLoading = true;
    });
    try {
      final stops = []; // TODO
      setState(() {
        _suggestions =
            stops
                .map(
                  (stop) => Location(
                    name: stop.name,
                    displayName: stop.name,
                    lat: stop.latitude ?? 0,
                    lon: stop.longitude ?? 0,
                  ),
                )
                .toList();
        _suggestionsLoading = false;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _suggestionsLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue ?? '';
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
        RawAutocomplete<Location>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Location>.empty();
            }
            return _suggestions;
          },
          displayStringForOption: (Location loc) => loc.displayName,
          onSelected: (Location selection) {
            setState(() {
              _controller.text = selection.displayName;
              _error = null;
            });
            widget.onLocationSelected(selection);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                isDense: true,
                labelText: widget.hintText,
                border: InputBorder.none,
                suffixIcon:
                    (_isLoading || _suggestionsLoading)
                        ? Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                        : IconButton(
                          icon: Icon(Icons.search),
                          onPressed: _search,
                        ),
                errorText: _error,
              ),
              onSubmitted: (_) => _search(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            if (_suggestionsLoading) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              );
            }
            if (options.isEmpty) {
              return SizedBox.shrink();
            }
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 200, minWidth: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Location option = options.elementAt(index);
                      return ListTile(
                        title: Text(option.displayName),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
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
