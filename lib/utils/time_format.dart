String formatHoursDecimal(int minutes) {
  if (minutes <= 0) return '0h';
  final hours = minutes / 60.0;
  // Limit to one decimal like 3.5h
  final value = (hours * 10).round() / 10.0;
  // Trim trailing .0
  if (value == value.roundToDouble()) {
    return '${value.toInt()}h';
  }
  return '${value}h';
}

/// Format minutes as compact hours and minutes like "61h24m" or "45m".
String formatHoursMinutes(int minutes) {
  if (minutes <= 0) return '0h';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h > 0 && m > 0) return '${h}h${m}m';
  if (h > 0) return '${h}h';
  return '${m}m';
}
