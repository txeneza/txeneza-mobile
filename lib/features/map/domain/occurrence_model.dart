import 'package:latlong2/latlong.dart';

enum OccurrenceStatus {
  pending,     // orange
  critical,    // red
  resolved,    // green
}

class Occurrence {
  final String id;
  final LatLng position; // Real geographic coordinates (latitude, longitude)
  final OccurrenceStatus status;
  final String title;
  final String description;
  final String? photoUrl;

  const Occurrence({
    required this.id,
    required this.position,
    required this.status,
    required this.title,
    required this.description,
    this.photoUrl,
  });
}
