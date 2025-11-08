// Utility formatting helpers used across the app
String formatPatrolDateTime(DateTime timestamp) {
  final tanggal =
      '${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}';
  final jam =
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  return jam.isNotEmpty ? "$tanggal $jam" : tanggal;
}
