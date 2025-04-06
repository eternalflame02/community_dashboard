import 'package:mongo_dart/mongo_dart.dart';
import 'package:latlong2/latlong.dart';

enum IncidentPriority { low, medium, high }
enum IncidentStatus { open, inProgress, resolved }

class Incident {
  final String id;
  final String title;
  final String description;
  final Map<String, dynamic> location;
  final String address;
  final String category;
  final IncidentPriority priority;
  final IncidentStatus status;
  final String reporterId;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.address,
    required this.category,
    required this.priority,
    required this.status,
    required this.reporterId,
    required this.images,
    required this.createdAt,
    this.resolvedAt,
  });

  LatLng get latLng => LatLng(
        location['coordinates'][1] as double, // latitude
        location['coordinates'][0] as double, // longitude
      );

  // From MongoDB
  factory Incident.fromMongoDB(Map<String, dynamic> doc) {
    return Incident(
      id: (doc['_id'] as ObjectId).toHexString(),
      title: doc['title'] as String,
      description: doc['description'] as String,
      location: doc['location'] as Map<String, dynamic>,
      address: doc['address'] as String,
      category: doc['category'] as String,
      priority: IncidentPriority.values[doc['priority'] as int],
      status: IncidentStatus.values[doc['status'] as int],
      reporterId: doc['reporterId'] as String,
      images: List<String>.from(doc['images'] as List),
      createdAt: doc['createdAt'] as DateTime,
      resolvedAt: doc['resolvedAt'] as DateTime?,
    );
  }

  // From generic JSON (for web/testing/mock data)
  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? {'coordinates': [0.0, 0.0]},
      address: json['address'] ?? '',
      category: json['category'] ?? '',
      priority: IncidentPriority.values[json['priority'] ?? 0],
      status: IncidentStatus.values[int.tryParse(json['status'] ?? '0') ?? 0], // Handle status as string
      reporterId: json['reporterId'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
    );
  }

  Map<String, dynamic> toMongoDB() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'address': address,
      'category': category,
      'priority': priority.index,
      'status': status.index,
      'reporterId': reporterId,
      'images': images,
      'createdAt': createdAt.toIso8601String(), // Convert DateTime to ISO 8601 string
      'resolvedAt': resolvedAt?.toIso8601String(), // Convert DateTime to ISO 8601 string if not null
    };
  }
}
