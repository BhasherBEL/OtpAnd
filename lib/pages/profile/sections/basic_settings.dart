import 'package:flutter/material.dart';

class BasicSettingsSection extends StatelessWidget {
  final TextEditingController nameController;
  final Color selectedColor;
  final Function(Color) onColorChanged;
  final List<Color> colorOptions;

  const BasicSettingsSection({
    super.key,
    required this.nameController,
    required this.selectedColor,
    required this.onColorChanged,
    required this.colorOptions,
  });

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 8,
      children: colorOptions.map((color) {
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selectedColor == color ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: color,
              radius: 18,
              child: selectedColor == color
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Profile Color',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildColorPicker(),
      ],
    );
  }
}

