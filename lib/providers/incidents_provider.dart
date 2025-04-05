import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';

class IncidentsProvider with ChangeNotifier {
  final IncidentService _incidentService = IncidentService();
  List<Incident> _incidents = [];
  String _searchQuery = '';
  String _filterCategory = '';
  IncidentStatus? _filterStatus;
  IncidentPriority? _filterPriority;

  List<Incident> get incidents => _filterIncidents();
  
  String get searchQuery => _searchQuery;
  String get filterCategory => _filterCategory;
  IncidentStatus? get filterStatus => _filterStatus;
  IncidentPriority? get filterPriority => _filterPriority;

  Stream<List<Incident>> get incidentsStream => _incidentService.getIncidents();

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterCategory(String category) {
    _filterCategory = category;
    notifyListeners();
  }

  void setFilterStatus(IncidentStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setFilterPriority(IncidentPriority? priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterCategory = '';
    _filterStatus = null;
    _filterPriority = null;
    notifyListeners();
  }

  List<Incident> _filterIncidents() {
    return _incidents.where((incident) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!incident.title.toLowerCase().contains(query) &&
            !incident.description.toLowerCase().contains(query) &&
            !incident.address.toLowerCase().contains(query)) {
          return false;
        }
      }

      if (_filterCategory.isNotEmpty &&
          incident.category.toLowerCase() != _filterCategory.toLowerCase()) {
        return false;
      }

      if (_filterStatus != null && incident.status != _filterStatus) {
        return false;
      }

      if (_filterPriority != null && incident.priority != _filterPriority) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> updateIncidentStatus(String id, IncidentStatus status) async {
    await _incidentService.updateIncidentStatus(id, status);
    // The stream will automatically update the UI
  }
}