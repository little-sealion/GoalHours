import 'package:flutter/material.dart';

/// Shows a simple HH:MM dialog and returns total minutes, or null if cancelled.
Future<int?> showManualEntryDialog(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  final hoursCtrl = TextEditingController();
  final minutesCtrl = TextEditingController();

  int? result;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Manual Entry'),
        content: Form(
          key: formKey,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: hoursCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Hours',
                    hintStyle: TextStyle(fontSize: 12),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // empty -> 0
                    final n = int.tryParse(v);
                    if (n == null || n < 0) return '>= 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 90,
                child: TextFormField(
                  controller: minutesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Minutes',
                    hintStyle: TextStyle(fontSize: 12),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // empty -> 0
                    final n = int.tryParse(v);
                    if (n == null || n < 0 || n > 59) return '0–59';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final rawH = int.tryParse(hoursCtrl.text.trim());
              final rawM = int.tryParse(minutesCtrl.text.trim());
              final h = (rawH == null) ? 0 : rawH.clamp(0, 1000000);
              final m = (rawM == null) ? 0 : rawM.clamp(0, 59);
              final total = h * 60 + m;
              if (total <= 0) {
                // Show a tiny inline error via snackbar for simplicity
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter more than 0 minutes')),
                );
                return;
              }
              result = total;
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );

  return result;
}
