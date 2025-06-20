import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateTimePickerMode { now, departure, arrival }

enum DateTimePrecisionMode { before, around, after }

class DateTimePickerValue {
  final DateTimePickerMode mode;
  final DateTime? dateTime;
  final DateTimePrecisionMode? precisionMode;

  DateTimePickerValue({required this.mode, this.dateTime, this.precisionMode});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateTimePickerValue &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          dateTime == other.dateTime;

  @override
  int get hashCode => mode.hashCode ^ (dateTime?.hashCode ?? 0);
}

class DateTimePicker extends StatelessWidget {
  final DateTimePickerValue value;
  final ValueChanged<DateTimePickerValue> onChanged;

  const DateTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  String _displayText(BuildContext context) {
    final timeFormat = DateFormat.Hm();
    final dateFormat = DateFormat('d MMM');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String friendlyDateLabel(DateTime date) {
      final d = DateTime(date.year, date.month, date.day);
      if (d == today) return '';
      if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
      if (d == today.add(const Duration(days: 1))) return 'Tomorrow';
      return dateFormat.format(date);
    }

    switch (value.mode) {
      case DateTimePickerMode.now:
        return 'Now: ${timeFormat.format(DateTime.now())}';
      case DateTimePickerMode.departure:
        if (value.dateTime != null) {
          final label = friendlyDateLabel(value.dateTime!);
          final time = timeFormat.format(value.dateTime!);
          if (label.isEmpty) {
            return 'Departure: $time';
          } else {
            return 'Departure: $label, $time';
          }
        }
        return 'Departure';
      case DateTimePickerMode.arrival:
        if (value.dateTime != null) {
          final label = friendlyDateLabel(value.dateTime!);
          final time = timeFormat.format(value.dateTime!);
          if (label.isEmpty) {
            return 'Arrival: $time';
          } else {
            return 'Arrival: $label, $time';
          }
        }
        return 'Arrival';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        _showPicker(context);
      },
      style: ButtonStyle(alignment: Alignment.centerLeft),
      child: Text(_displayText(context)),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final result = await showDialog<DateTimePickerValue>(
      context: context,
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Dialog(
              insetPadding: EdgeInsets.zero,
              child: _DateTimePickerModal(initialValue: value),
            ),
          ),
        );
      },
    );
    if (result != null) {
      onChanged(result);
    }
  }
}

class _DateTimePickerModal extends StatefulWidget {
  final DateTimePickerValue initialValue;

  const _DateTimePickerModal({required this.initialValue});

  @override
  State<_DateTimePickerModal> createState() => _DateTimePickerModalState();
}

class _DateTimePickerModalState extends State<_DateTimePickerModal>
    with SingleTickerProviderStateMixin {
  String _friendlyDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (d == today.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('d MMM yyyy').format(date);
  }

  late TabController _tabController;
  late DateTimePickerMode _selectedMode;
  late DateTimePrecisionMode _selectedPrecisionMode;
  late DateTime _selectedDateTime;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialValue.mode;
    _selectedDateTime = widget.initialValue.dateTime ?? DateTime.now();
    _selectedPrecisionMode =
        widget.initialValue.precisionMode ?? DateTimePrecisionMode.around;
    int initialTabIndex = _selectedMode == DateTimePickerMode.now
        ? DateTimePickerMode.departure.index
        : _selectedMode.index;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialTabIndex,
    );
    if (_selectedMode == DateTimePickerMode.now) {
      _selectedMode = DateTimePickerMode.departure;
      _selectedPrecisionMode = DateTimePrecisionMode.after;
    }
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        final newMode = DateTimePickerMode.values[_tabController.index];
        if (newMode == DateTimePickerMode.now) {
          Navigator.of(
            context,
          ).pop(DateTimePickerValue(
            mode: newMode,
            dateTime: DateTime.now(),
            precisionMode: _selectedPrecisionMode,
          ));
        } else {
          _selectedMode = newMode;
        }
      });
    });

    _hourController = FixedExtentScrollController(
      initialItem: _selectedDateTime.hour,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedDateTime.minute,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
        _hourController.jumpToItem(_selectedDateTime.hour);
        _minuteController.jumpToItem(_selectedDateTime.minute);
      });
    }
  }

  // Time is now picked via scroll wheels in the modal, so this is no longer needed.

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Now'),
            Tab(text: 'Departure'),
            Tab(text: 'Arrival'),
          ],
        ),
        if (_selectedMode != DateTimePickerMode.now)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      RadioListTile<DateTimePrecisionMode>(
                        title: const Text('Before'),
                        contentPadding: EdgeInsets.all(0),
                        visualDensity: VisualDensity(vertical: -4),
                        value: DateTimePrecisionMode.before,
                        groupValue: _selectedPrecisionMode,
                        onChanged: (DateTimePrecisionMode? mode) {
                          if (mode == null) return;
                          setState(() {
                            _selectedPrecisionMode = mode;
                          });
                        },
                      ),
                      RadioListTile<DateTimePrecisionMode>(
                        title: const Text('Around'),
                        contentPadding: EdgeInsets.all(0),
                        visualDensity: VisualDensity(vertical: -4),
                        value: DateTimePrecisionMode.around,
                        groupValue: _selectedPrecisionMode,
                        onChanged: (DateTimePrecisionMode? mode) {
                          if (mode == null) return;
                          setState(() {
                            _selectedPrecisionMode = mode;
                          });
                        },
                      ),
                      RadioListTile<DateTimePrecisionMode>(
                        title: const Text('After'),
                        contentPadding: EdgeInsets.all(0),
                        visualDensity: VisualDensity(vertical: -4),
                        value: DateTimePrecisionMode.after,
                        groupValue: _selectedPrecisionMode,
                        onChanged: (DateTimePrecisionMode? mode) {
                          if (mode == null) return;
                          setState(() {
                            _selectedPrecisionMode = mode;
                          });
                        },
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 100,
                            child: ListWheelScrollView.useDelegate(
                              itemExtent: 32,
                              diameterRatio: 1.2,
                              physics: const FixedExtentScrollPhysics(),
                              controller: _hourController,
                              onSelectedItemChanged: (int index) {
                                setState(() {
                                  _selectedDateTime = DateTime(
                                    _selectedDateTime.year,
                                    _selectedDateTime.month,
                                    _selectedDateTime.day,
                                    index,
                                    _selectedDateTime.minute,
                                  );
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  if (index < 0 || index > 23) return null;
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  );
                                },
                                childCount: 24,
                              ),
                            ),
                          ),
                          const Text(':', style: TextStyle(fontSize: 18)),
                          // Minute wheel
                          SizedBox(
                            width: 50,
                            height: 100,
                            child: ListWheelScrollView.useDelegate(
                              itemExtent: 32,
                              diameterRatio: 1.2,
                              physics: const FixedExtentScrollPhysics(),
                              controller: _minuteController,
                              onSelectedItemChanged: (int index) {
                                setState(() {
                                  _selectedDateTime = DateTime(
                                    _selectedDateTime.year,
                                    _selectedDateTime.month,
                                    _selectedDateTime.day,
                                    _selectedDateTime.hour,
                                    index,
                                  );
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  if (index < 0 || index > 59) return null;
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  );
                                },
                                childCount: 60,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                _selectedDateTime = DateTime(
                                  _selectedDateTime.year,
                                  _selectedDateTime.month,
                                  _selectedDateTime.day - 1,
                                  _selectedDateTime.hour,
                                  _selectedDateTime.minute,
                                );
                                _hourController.jumpToItem(
                                  _selectedDateTime.hour,
                                );
                                _minuteController.jumpToItem(
                                  _selectedDateTime.minute,
                                );
                              });
                            },
                          ),
                          TextButton(
                            onPressed: _pickDate,
                            child: Text(_friendlyDateLabel(_selectedDateTime)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                _selectedDateTime = DateTime(
                                  _selectedDateTime.year,
                                  _selectedDateTime.month,
                                  _selectedDateTime.day + 1,
                                  _selectedDateTime.hour,
                                  _selectedDateTime.minute,
                                );
                                _hourController.jumpToItem(
                                  _selectedDateTime.hour,
                                );
                                _minuteController.jumpToItem(
                                  _selectedDateTime.minute,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    DateTimePickerValue(
                      mode: _selectedMode,
                      dateTime: _selectedMode == DateTimePickerMode.now
                          ? DateTime.now()
                          : _selectedDateTime,
                      precisionMode: _selectedPrecisionMode,
                    ),
                  );
                },
                child: const Text('Ok'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
