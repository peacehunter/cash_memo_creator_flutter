import 'package:flutter/material.dart';

class TemplatePickerDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> templates = [
      {
        'name': 'Standard (Default)',
        'icon': Icons.receipt_long,
        'color': const Color(0xFF0f172a),
        'description': 'Bold Courier font with clear borders',
      },
      {
        'name': 'Compact',
        'icon': Icons.note,
        'color': Colors.blueGrey,
        'description': 'Space-efficient design with tight padding',
      },
      {
        'name': 'Modern Accent',
        'icon': Icons.sticky_note_2,
        'color': Color(0xFF059669),
        'description': 'Green accent with left border highlight',
      },
      {
        'name': 'Classic',
        'icon': Icons.history_edu,
        'color': Color(0xFF7c4700),
        'description': 'Traditional formal style with brown border',
      },
      {
        'name': 'Bordered',
        'icon': Icons.border_color,
        'color': Color(0xFF475569),
        'description': 'Blue-grey theme with banner header',
      },
      {
        'name': 'Bold Headings',
        'icon': Icons.text_fields,
        'color': Color(0xFFef4444),
        'description': 'Eye-catching red gradient with bold text',
      },
      {
        'name': 'Minimalist Elegance',
        'icon': Icons.fiber_manual_record_outlined,
        'color': Color(0xFF6B7280),
        'description': 'Clean minimalist design with subtle lines',
      },
      {
        'name': 'Professional Invoice',
        'icon': Icons.business_center,
        'color': Color(0xFF1E3A8A),
        'description': 'Corporate invoice style with detailed breakdown',
      },
      {
        'name': 'Creative Gradient',
        'icon': Icons.gradient,
        'color': Color(0xFF9333EA),
        'description': 'Modern purple-pink gradient design',
      },
    ];
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.palette, color: Color(0xFF059669)),
          SizedBox(width: 8),
          Text('Select PDF Template'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: templates
                .map((tpl) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: tpl['color'],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (tpl['color'] as Color).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(tpl['icon'], color: Colors.white, size: 28),
                        ),
                        title: Text(
                          tpl['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: tpl['description'] != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  tpl['description'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              )
                            : null,
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.pop(context, tpl['name'] as String),
                        hoverColor: (tpl['color'] as Color).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
