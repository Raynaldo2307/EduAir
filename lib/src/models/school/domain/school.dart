class School {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;
  final String timezone;
  const School ({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.radiusMeters = 200.0,
    this.timezone = 'America/Jamaica',

  });
}