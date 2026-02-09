import 'package:flutter/material.dart';

class ReportDialog extends StatefulWidget {
  final Function(String reason, String? description) onSubmit;

  const ReportDialog({super.key, required this.onSubmit});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final TextEditingController _descCtrl = TextEditingController();

  final reasons = const [
    'SPAM',
    'HATE',
    'NSFW',
    'SPOILER',
    'OFFTOPIC',
    'OTHER',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(label: Text("Reason")),
            value: _selectedReason,
            items: reasons
                .map((r) =>
                    DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _selectedReason = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  widget.onSubmit(_selectedReason!, _descCtrl.text.trim().isEmpty
                      ? null
                      : _descCtrl.text.trim());
                  Navigator.pop(context);
                },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
