import 'package:latlong2/latlong.dart';

enum IncidentPriority {
  low,
  medium,
  high
}

enum IncidentStatus {
  open,
  inProgress,
  resolved
}

class Incident {
  final String id;
  final String title;
  final String description;
  final Map<String, dynamic> location;
  final String address;
  final String category;
  final IncidentStatus status;
  final IncidentPriority priority;
  final String reporterId;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? inProgressBy;
  final DateTime? inProgressAt;
  final String? resolvedBy;

  Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.address,
    required this.category,
    required this.status,
    required this.priority,
    required this.reporterId,
    required this.images,
    required this.createdAt,
    this.resolvedAt,
    this.inProgressBy,
    this.inProgressAt,
    this.resolvedBy,
  });

  // Getter for LatLng to use with flutter_map
  LatLng get latLng {
    final coordinates = location['coordinates'] as List;
    return LatLng(coordinates[1], coordinates[0]); // [longitude, latitude] to [latitude, longitude]
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['_id'] ?? '',
      title: json['title'] as String,
      description: json['description'] as String,
      location: json['location'] as Map<String, dynamic>,
      address: json['address'] as String,
      category: json['category'] as String,
      status: _parseStatus(json['status'] as String),
      priority: _parsePriority(json['priority'] as int),
      reporterId: json['reporterId'] as String,
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
      inProgressBy: json['inProgressBy'],
      inProgressAt: json['inProgressAt'] != null ? DateTime.parse(json['inProgressAt']) : null,
      resolvedBy: json['resolvedBy'],
    );
  }

  static IncidentStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return IncidentStatus.open;
      case 'inprogress':
        return IncidentStatus.inProgress;
      case 'resolved':
        return IncidentStatus.resolved;
      default:
        return IncidentStatus.open;
    }
  }

  static IncidentPriority _parsePriority(int priority) {
    switch (priority) {
      case 0:
        return IncidentPriority.low;
      case 1:
        return IncidentPriority.medium;
      case 2:
        return IncidentPriority.high;
      default:
        return IncidentPriority.medium;
    }
  }
}
