import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/incident.dart';
import 'dart:math' show pi, cos;

class IncidentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'incidents';

  Stream<List<Incident>> getIncidents({IncidentStatus? status}) {
    try {
      Query query = _firestore.collection(_collection);
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.index);
      }
      
      return query
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => Incident.fromFirestore(doc))
                .toList();
          })
          .handleError((error) {
            debugPrint('Error fetching incidents: $error');
            return [];
          });
    } catch (e) {
      debugPrint('Error setting up incidents stream: $e');
      return Stream.value([]);
    }
  }

  Stream<List<Incident>> getNearbyIncidents(GeoPoint center, double radiusKm) {
    try {
      // Calculate the bounding box for the radius
      final double lat = center.latitude;
      final double lon = center.longitude;
      final double latChange = radiusKm / 111.32; // 1 degree = 111.32 km
      final double lonChange = radiusKm / (111.32 * cos(lat * pi / 180));

      final double minLat = lat - latChange;
      final double maxLat = lat + latChange;
      final double minLon = lon - lonChange;
      final double maxLon = lon + lonChange;

      return _firestore
          .collection(_collection)
          .where('location.latitude', isGreaterThanOrEqualTo: minLat)
          .where('location.latitude', isLessThanOrEqualTo: maxLat)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => Incident.fromFirestore(doc))
                .where((incident) {
                  final incidentLon = incident.location.longitude;
                  return incidentLon >= minLon && incidentLon <= maxLon;
                })
                .toList();
          })
          .handleError((error) {
            debugPrint('Error fetching nearby incidents: $error');
            return [];
          });
    } catch (e) {
      debugPrint('Error setting up nearby incidents stream: $e');
      return Stream.value([]);
    }
  }

  Future<Incident> createIncident(Incident incident) async {
    try {
      // Validate incident data
      if (incident.title.isEmpty) {
        throw Exception('Incident title cannot be empty');
      }
      if (incident.location == null) {
        throw Exception('Incident location is required');
      }

      final docRef = await _firestore.collection(_collection).add(
        incident.toFirestore(),
      );
      
      final doc = await docRef.get();
      return Incident.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error creating incident: $e');
      rethrow;
    }
  }

  Future<void> updateIncidentStatus(String id, IncidentStatus status) async {
    try {
      if (id.isEmpty) {
        throw Exception('Incident ID cannot be empty');
      }

      await _firestore.collection(_collection).doc(id).update({
        'status': status.index,
        if (status == IncidentStatus.resolved) 'resolvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating incident status: $e');
      rethrow;
    }
  }
}