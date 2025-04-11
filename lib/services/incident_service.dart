import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/incident.dart';
import '../config/mongodb_config.dart';
import 'mongodb_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

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
      final response = await http.get(Uri.parse('http://localhost:3000/incidents'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        yield data.map((json) => Incident.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch incidents: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching incidents: $e');
      throw Exception('An unexpected error occurred while fetching incidents.');
    }
  }

  Stream<List<Incident>> getNearbyIncidents(LatLng center, double radiusKm) async* {
    throw UnimplementedError('Nearby incidents feature is not supported in the web environment.');
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
        debugPrint('Error response body: ${response.body}');
        throw Exception('Failed to load incidents: ${response.body}');
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
        body: jsonEncode({'status': status.name}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update incident status');
      }
    } catch (e) {
      debugPrint('Error updating incident status: $e');
      throw Exception('An unexpected error occurred while updating the incident status.');
    }
  }

  Future<List<String>> _compressAndUploadImages(List<XFile> images) async {
    final List<String> base64Images = [];
    for (final image in images) {
      final bytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(Uint8List.fromList(bytes));
      if (decodedImage != null) {
        final compressedImage = img.encodeJpg(decodedImage, quality: 70); // Compress to 70% quality
        base64Images.add(base64Encode(compressedImage));
      }
    }
    return base64Images;
  }
}