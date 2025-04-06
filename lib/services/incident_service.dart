import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/incident.dart';
import '../config/mongodb_config.dart';
import 'mongodb_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IncidentService extends ChangeNotifier {
  String _searchQuery = '';
  IncidentStatus? _filterStatus;
  String? _filterCategory;
  IncidentPriority? _filterPriority;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }


  String get searchQuery => _searchQuery;

  void clearFilters() {
    _searchQuery = '';
    _filterStatus = null;
    _filterCategory = null;
    _filterPriority = null;
    notifyListeners();
  }

  void setFilterStatus(IncidentStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setFilterCategory(String category) {
    _filterCategory = category;
    notifyListeners();
  }

  void setFilterPriority(IncidentPriority priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  IncidentStatus? get filterStatus => _filterStatus;
  String? get filterCategory => _filterCategory;
  IncidentPriority? get filterPriority => _filterPriority;

  Stream<List<Incident>> getIncidents({IncidentStatus? status}) async* {
    try {
      final collection = MongoDBService.getCollection(MongoConfig.incidentsCollection);
      
      final query = status != null ? where.eq('status', status.index) : where;
      if (_filterCategory != null) {
        query.and(where.eq('category', _filterCategory));
      }
      if (_filterPriority != null) {
        query.and(where.eq('priority', _filterPriority!.index));
      }
      query.sortBy('createdAt', descending: true);

      final cursor = collection.find(query);
      final incidents = <Incident>[];
      await for (final doc in cursor) {
        try {
          incidents.add(Incident.fromMongoDB(doc));
          yield incidents;
        } catch (e) {
          debugPrint('Error parsing incident: $e');
          throw Exception('An unexpected error occurred while processing incidents. Please try again later.');
        }
      }
    } catch (e) {
      debugPrint('Error fetching incidents: $e');
      throw Exception('An unexpected error occurred while processing incidents. Please try again later.');
    }
  }

  Stream<List<Incident>> getNearbyIncidents(LatLng center, double radiusKm) async* {
    try {
      final collection = MongoDBService.getCollection(MongoConfig.incidentsCollection);
      
      // MongoDB geospatial query
      final query = where.near('location', 
        [center.longitude, center.latitude],
        radiusKm * 1000, // Convert to meters
      );

      final cursor = collection.find(query);
      final incidents = <Incident>[];
      
      await for (final doc in cursor) {
        try {
          incidents.add(Incident.fromMongoDB(doc));
          yield incidents;
        } catch (e) {
          debugPrint('Error parsing incident: $e');
          throw Exception('An unexpected error occurred while processing incidents. Please try again later.');
        }
      }
    } catch (e) {
      debugPrint('Error fetching nearby incidents: $e');
      throw Exception('An unexpected error occurred while processing incidents. Please try again later.');
    }
  }

  Future<List<Incident>> fetchIncidents() async {
    try {
      debugPrint('Fetching incidents from backend...');
      final response = await http.get(Uri.parse('http://localhost:3000/incidents'));
      debugPrint('Backend response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Incident.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load incidents');
      }
    } catch (e) {
      debugPrint('Error fetching incidents: $e');
      throw Exception('An unexpected error occurred while fetching incidents.');
    }
  }

  Future<Incident> createIncident(Incident incident) async {
    try {
      debugPrint('Sending incident data to backend:');
      debugPrint(incident.toMongoDB().toString());

      final response = await http.post(
        Uri.parse('http://localhost:3000/incidents'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(incident.toMongoDB()),
      );

      debugPrint('Backend response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return Incident.fromJson(jsonDecode(response.body));
      } else {
        debugPrint('Failed to create incident: ${response.body}');
        throw Exception('Failed to create incident');
      }
    } catch (e) {
      debugPrint('Error creating incident: $e');
      throw Exception('An unexpected error occurred while creating the incident.');
    }
  }

  Future<void> updateIncidentStatus(String id, IncidentStatus status) async {
    try {
      final response = await http.patch(
        Uri.parse('http://localhost:3000/incidents/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status.index}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update incident status');
      }
    } catch (e) {
      debugPrint('Error updating incident status: $e');
      throw Exception('An unexpected error occurred while updating the incident status.');
    }
  }
}