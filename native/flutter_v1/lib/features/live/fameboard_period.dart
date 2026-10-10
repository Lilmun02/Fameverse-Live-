/// Fameboard resets are UTC calendar periods, never rolling hour windows.
DateTime fameboardStartUtc(String window, DateTime now) {
  final utc = now.toUtc();
  final todayUtc = DateTime.utc(utc.year, utc.month, utc.day);
  switch (window) {
    case '24h':
      return todayUtc;
    case '7d':
      return todayUtc.subtract(Duration(days: utc.weekday - DateTime.monday));
    default:
      throw ArgumentError.value(window, 'window', 'Unsupported Fameboard window');
  }
}

DateTime fameboardEndUtc(String window, DateTime now) {
  final start = fameboardStartUtc(window, now);
  switch (window) {
    case '24h':
      return DateTime.utc(start.year, start.month, start.day + 1);
    case '7d':
      return DateTime.utc(start.year, start.month, start.day + 7);
    default:
      throw ArgumentError.value(window, 'window', 'Unsupported Fameboard window');
  }
}

String fameboardCountdown(Duration remaining) {
  final seconds = remaining.inSeconds.clamp(0, 604800);
  final days = seconds ~/ 86400;
  final hours = (seconds ~/ 3600) % 24;
  final minutes = (seconds ~/ 60) % 60;
  final last = seconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  final clock = two(hours) + ':' + two(minutes) + ':' + two(last);
  return days > 0 ? days.toString() + 'd ' + clock : clock;
}
