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

  // Optimized `fetchIncidents` with pagination support
  Future<List<Incident>> fetchIncidents({int page = 1, int limit = 10}) async {
    try {
      debugPrint('Fetching incidents from backend (page: $page, limit: $limit)...');
      final response = await http.get(Uri.parse('http://localhost:3000/incidents?page=$page&limit=$limit'));
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

  Future<void> createIncident(Incident incident) async {
    await MongoDBService.initialize(); // Ensure MongoDB is initialized
    final collection = MongoDBService.getCollection('incidents');

    // Updated image handling to remove `File` usage and ensure compatibility with Flutter Web
    final base64Images = incident.images.map((image) {
      final bytes = kIsWeb
          ? base64Decode(image) // Decode Base64 directly for web
          : Uint8List.fromList(image.codeUnits); // Use Uint8List for other platforms
      return base64Encode(bytes);
    }).toList();

    final document = {
      'title': incident.title,
      'description': incident.description,
      'location': incident.location,
      'address': incident.address,
      'category': incident.category,
      'priority': incident.priority.name,
      'status': incident.status.name,
      'reporterId': incident.reporterId,
      'images': base64Images, // Store Base64-encoded images
      'createdAt': incident.createdAt.toIso8601String(),
      'resolvedAt': incident.resolvedAt?.toIso8601String(),
    };

    await collection.insertOne(document);
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

  // Added `incidentStream` getter to provide a stream of incidents
  Stream<List<Incident>> get incidentStream async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 5)); // Poll every 5 seconds
      yield await fetchIncidents();
    }
  }
}