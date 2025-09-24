import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/project.dart';
import '../../data/project_repo.dart';

class EditProjectPage extends StatefulWidget {
  const EditProjectPage({super.key, this.projectId});

  final int? projectId;

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();

  bool _saving = false;
  bool _loading = false;
  int? _editingProjectColor;
  int? _editingProjectId;

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _loadProject(widget.projectId!);
    }
  }

  Future<void> _loadProject(int id) async {
    setState(() => _loading = true);
    try {
      final repo = context.read<ProjectRepo>();
      final p = await repo.get(id);
      if (p != null) {
        _editingProjectId = p.id;
        _nameCtrl.text = p.name;
        _goalCtrl.text = (p.goalMinutes ~/ 60).toString();
        _editingProjectColor = p.color;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
      if (_editingProjectId == null) {
        final project = Project()
          ..name = _nameCtrl.text.trim()
          ..color = Theme.of(context).colorScheme.primary.toARGB32()
          ..goalMinutes = minutes
          ..createdAtUtc = DateTime.now().toUtc()
          // New projects start as active; archive is managed from the list menu.
          ..archived = false;
        await repo.add(project);
      } else {
        final existing = await repo.get(_editingProjectId!);
        if (existing != null) {
          existing
            ..name = _nameCtrl.text.trim()
            ..goalMinutes = minutes
            // Preserve existing archived state; editing does not change it here.
            ..archived = existing.archived
            ..color = _editingProjectColor ?? existing.color; // preserve color
          await repo.update(existing);
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEditing = _editingProjectId != null || widget.projectId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Project' : 'New Project'),
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
                    if (_loading)
                      const LinearProgressIndicator(),
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
                            : Text(isEditing ? 'Save' : 'Create', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
