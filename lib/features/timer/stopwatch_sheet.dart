import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalhours/data/session_repo.dart';

class StopwatchSheet extends StatefulWidget {
  const StopwatchSheet({super.key, required this.projectId, required this.projectName, this.accent});

  final int projectId;
  final String projectName;
  final Color? accent;

  @override
  State<StopwatchSheet> createState() => _StopwatchSheetState();
}

class _StopwatchSheetState extends State<StopwatchSheet> {
  Timer? _ticker;
  bool _running = false;
  Duration _accumulated = Duration.zero;
  DateTime? _lastStart;
  bool _stopped = false; // after stop, time is frozen until save
  bool _showConfirm = false; // show "will add ..." message before save

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_running) setState(() {}); // repaint to update elapsed text
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration get _elapsedNow {
    if (_running && _lastStart != null) {
      return _accumulated + DateTime.now().difference(_lastStart!);
    }
    return _accumulated;
  }

  

  String _formatHMS(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _start() {
    if (_running) return;
    setState(() {
      _running = true;
      _lastStart = DateTime.now();
    });
  }

  void _pause() {
    if (!_running) return;
    final now = DateTime.now();
    setState(() {
      _accumulated += now.difference(_lastStart!);
      _lastStart = null;
      _running = false;
    });
  }

  void _stop() {
    if (_stopped) return;
    if (_running) _pause();
    setState(() {
      _stopped = true;
      _showConfirm = true; // show message prompting save
    });
  }

  Future<void> _save() async {
    final total = _elapsedNow;
    final seconds = total.inSeconds;
    if (seconds <= 0) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
    try {
      final repo = context.read<SessionRepo>();
      await repo.addManualEntrySeconds(widget.projectId, seconds);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save time: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accent ?? Theme.of(context).colorScheme.primary;
    final elapsed = _elapsedNow;
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              widget.projectName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _formatHMS(elapsed),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_stopped && !_running && elapsed == Duration.zero) ...[
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                ] else if (!_stopped && _running) ...[
                  OutlinedButton.icon(
                    onPressed: _pause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _stop,
                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ] else if (!_stopped && !_running) ...[
                  // paused state (not yet stopped)
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _stop,
                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ] else ...[
                  // stopped state: show Save button (always enabled)
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (_showConfirm) ...[
              Builder(builder: (context) {
                final label = _formatHMS(elapsed);
                return Text(
                  'Will add $label to ${widget.projectName}.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                );
              }),
              const SizedBox(height: 2),
              Builder(builder: (context) {
                if (elapsed.inSeconds > 0) return const SizedBox.shrink();
                final base = Theme.of(context).textTheme.bodySmall;
                final c = base?.color;
                return Text(
                  '< 1m, keep going',
                  style: base?.copyWith(color: c?.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                );
              }),
            ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String minutesLabel(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}
