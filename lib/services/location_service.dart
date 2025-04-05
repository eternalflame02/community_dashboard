import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

class LocationService {
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  Future<String> getAddressFromCoordinates(LatLng coordinates) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_nominatimBaseUrl/reverse?format=json&lat=${coordinates.latitude}&lon=${coordinates.longitude}&addressdetails=1',
        ),
        headers: {
          'User-Agent': 'community_dashboard',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? '';
      }
      
      throw Exception('Failed to get address');
    } catch (e) {
      throw Exception('Error getting address: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_nominatimBaseUrl/search?format=json&q=${Uri.encodeComponent(query)}',
        ),
        headers: {
          'User-Agent': 'community_dashboard',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      }
      
      throw Exception('Failed to search address');
    } catch (e) {
      throw Exception('Error searching address: $e');
    }
  }
}