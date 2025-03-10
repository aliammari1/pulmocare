import 'package:flutter/material.dart';

class ColorPicker extends StatelessWidget {
  final Function(Color) onColorChanged;

  const ColorPicker({
    super.key,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildColorOption(Colors.black),
        _buildColorOption(Colors.red),
        _buildColorOption(Colors.green),
        _buildColorOption(Colors.blue),
        _buildColorOption(Colors.yellow),
        _buildColorOption(Colors.purple),
        _buildColorOption(Colors.orange),
        _buildColorOption(Colors.teal),
        _buildColorOption(Colors.pink),
        _buildColorOption(Colors.indigo),
      ],
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
    );
  }
}
