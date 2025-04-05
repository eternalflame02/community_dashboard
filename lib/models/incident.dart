import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

enum IncidentPriority { low, medium, high }
enum IncidentStatus { open, inProgress, resolved }

class Incident {
  final String id;
  final String title;
  final String description;
  final GeoPoint location;
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

  LatLng get latLng => LatLng(location.latitude, location.longitude);

  factory Incident.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Incident(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] as GeoPoint,
      address: data['address'] ?? '',
      category: data['category'] ?? '',
      priority: IncidentPriority.values[data['priority'] ?? 0],
      status: IncidentStatus.values[data['status'] ?? 0],
      reporterId: data['reporterId'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
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
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }
}