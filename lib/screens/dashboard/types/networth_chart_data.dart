class NetworthChartData {
  final DateTime date;
  final double value;
  final String type; // 'current' or 'future'

  NetworthChartData({
    required this.date,
    required this.value,
    required this.type,
  });

  @override
  String toString() {
    return 'NetworthChartData{date: $date, value: $value, type: $type}';
  }
}
