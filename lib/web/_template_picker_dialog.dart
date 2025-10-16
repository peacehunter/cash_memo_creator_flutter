import 'package:flutter/material.dart';

class TemplatePickerDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> templates = [
      {
        'name': 'Standard (Default)',
        'icon': Icons.receipt_long,
        'color': const Color(0xFF0f172a),
      },
      {
        'name': 'Compact',
        'icon': Icons.note,
        'color': Colors.blueGrey,
      },
      {
        'name': 'Modern Accent',
        'icon': Icons.sticky_note_2,
        'color': Color(0xFF059669),
      },
      {
        'name': 'Classic',
        'icon': Icons.history_edu,
        'color': Color(0xFF7c4700),
      },
      {
        'name': 'Bordered',
        'icon': Icons.border_color,
        'color': Color(0xFF475569),
      },
      {
        'name': 'Bold Headings',
        'icon': Icons.text_fields,
        'color': Color(0xFFef4444),
      },
    ];
    return AlertDialog(
      title: const Text('Select PDF Template'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: templates
            .map((tpl) => ListTile(
                  leading: CircleAvatar(
                      backgroundColor: tpl['color'],
                      child: Icon(tpl['icon'], color: Colors.white)),
                  title: Text(tpl['name'],
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.pop(context, tpl['name'] as String),
                ))
            .toList(),
      ),
      actions: [
        TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
