import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/project.dart';
import '../../data/project_repo.dart';

class EditProjectPage extends StatefulWidget {
  const EditProjectPage({super.key});

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final repo = context.read<ProjectRepo>();
      final hours = int.parse(_goalCtrl.text.trim());
      final minutes = hours * 60;
      final project = Project()
        ..name = _nameCtrl.text.trim()
        ..color = Theme.of(context).colorScheme.primary.value
        ..goalMinutes = minutes
        ..createdAtUtc = DateTime.now().toUtc();

      await repo.add(project);

      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Hours'),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What is your goal?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. English learning'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a goal' : null,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'How many hours would you like to input for your goal?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _goalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'e.g. 1000 (hours)'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Enter a positive number of hours';
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.surfaceContainerHighest,
                          foregroundColor: Colors.black,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(24),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
