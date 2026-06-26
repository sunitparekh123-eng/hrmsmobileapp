import 'dart:math';

/// Represents an office/company location with geo-fence boundary
class OfficeLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const OfficeLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 50.0,
  });

  /// Delhi Office — Karan Joshi's testing location
  static const OfficeLocation indoreHub = OfficeLocation(
    id: 'LOC-DEL',
    name: 'NexGen Technologies — Delhi Office',
    address: 'Delhi NCR',
    latitude: 28.728311,
    longitude: 77.245483,
    radiusMeters: 200.0,
  );

  /// Returns all office locations the employee can punch from
  static const List<OfficeLocation> all = [indoreHub];
}

/// Result of a geo-fence validation check
enum GeoFenceStatus {
  withinRange,
  outOfRange,
  unknown,
}

/// Punch type
enum PunchType { punchIn, punchOut }

/// A single punch record (in or out) with geo-location data
class PunchRecord {
  final PunchType type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String locationName;
  final double distanceFromOffice;
  final GeoFenceStatus geoFenceStatus;
  final bool isLate;
  final int? lateByMinutes;
  final String? photoPath;

  const PunchRecord({
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.distanceFromOffice,
    required this.geoFenceStatus,
    this.isLate = false,
    this.lateByMinutes,
    this.photoPath,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get typeLabel => type == PunchType.punchIn ? 'Punch In' : 'Punch Out';
}

/// Geo-location utility functions
class GeoUtils {
  GeoUtils._();

  static const double earthRadiusMeters = 6371000;

  /// Haversine formula to calculate distance in meters between two coordinates
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Check if a coordinate is within the geo-fence radius of an office
  static bool isWithinRadius(
    double userLat,
    double userLon,
    OfficeLocation office,
  ) {
    final distance = calculateDistance(
      userLat,
      userLon,
      office.latitude,
      office.longitude,
    );
    return distance <= office.radiusMeters;
  }

  /// Get formatted distance string
  static String formatDistance(double meters) {
    if (meters < 1) return '<1 m';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}