import 'package:intl/intl.dart';

/// "15 Oct 2026, 11:42".
String formatDateTime(DateTime value) =>
    DateFormat('d MMM yyyy, HH:mm').format(value.toLocal());

/// "15 Oct".
String formatDay(DateTime value) => DateFormat('d MMM').format(value.toLocal());

/// "4m 12s" / "38s".
String formatDuration(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds % 60;
  if (minutes == 0) return '${seconds}s';
  return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
}

/// "just now", "4 min ago", "2 h ago", "3 d ago".
String formatAgo(DateTime value, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(value);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return formatDay(value);
}
