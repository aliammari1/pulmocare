import 'package:flutter/material.dart';

class EntityHighlight extends StatelessWidget {
  final String text;
  final String type;
  final double confidence;
  final void Function() onTap;
  final void Function()? onClose;

  const EntityHighlight({
    super.key,
    required this.text,
    required this.type,
    required this.confidence,
    required this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(text),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: $type'),
                LinearProgressIndicator(
                  value: confidence,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    confidence > 0.7
                        ? Colors.green
                        : confidence > 0.4
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%'),
              ],
            ),
            trailing: onClose != null
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  )
                : null,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
