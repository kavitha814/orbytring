class VitalRecord {
  final DateTime timestamp;
  final double value;

  VitalRecord({
    required this.timestamp,
    required this.value,
  });

  @override
  String toString() => 'VitalRecord(time: $timestamp, value: $value)';
}
