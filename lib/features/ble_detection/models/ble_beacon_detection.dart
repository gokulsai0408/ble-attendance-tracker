class BleBeaconDetection {
  final String deviceId;
  final String deviceName;
  final String serviceUuid;
  final List<int> rssiValues;
  final DateTime detectedAt;

  BleBeaconDetection({
    required this.deviceId,
    required this.deviceName,
    required this.serviceUuid,
    required this.rssiValues,
    required this.detectedAt,
  });

  /// Compatibility getter for single RSSI value
  int get rssi => averageRssi.toInt();

  double get averageRssi {
    if (rssiValues.isEmpty) return -100.0;
    return rssiValues.reduce((a, b) => a + b) / rssiValues.length;
  }

  bool get isPresenceValid => averageRssi > -70;

  String get proximityStatus {
    final avg = averageRssi;
    if (avg > -60) return "Immediate";
    if (avg > -70) return "Near";
    return "Far / Invalid";
  }
}
