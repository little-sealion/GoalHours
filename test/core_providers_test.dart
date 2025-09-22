import 'package:flutter_test/flutter_test.dart';
import 'package:goalhours/data/session.dart';

void main() {
  test('Session durationMinutes computes correctly', () {
    final end = DateTime.utc(2025, 1, 1, 12, 30);
    final start = end.subtract(const Duration(minutes: 90));
    final s = Session()
      ..isManual = false
      ..projectId = 1
      ..startUtc = start
      ..endUtc = end
      ..createdAtUtc = DateTime.utc(2025, 1, 1);
    expect(s.durationMinutes, 90);
  });

  test('Manual session uses manualDurationMinutes', () {
    final s = Session()
      ..isManual = true
      ..projectId = 1
      ..startUtc = DateTime.utc(2025, 1, 1)
      ..endUtc = DateTime.utc(2025, 1, 1, 1)
      ..manualDurationMinutes = 42
      ..createdAtUtc = DateTime.utc(2025, 1, 1);
    expect(s.durationMinutes, 42);
  });
}
