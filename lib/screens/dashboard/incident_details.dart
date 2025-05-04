import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import '../../models/incident.dart';
import '../../services/incident_service.dart';
import '../../services/auth_service.dart'; // Ensure AuthService is imported
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../config/api.dart';
import 'dart:convert';
import 'edit_incident_screen.dart'; // Import the EditIncidentScreen widget

class IncidentDetailsPopup extends StatelessWidget {
  final Incident incident;

  const IncidentDetailsPopup({
    super.key,
    required this.incident,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 16,
          top: 16,
          child: Card(
            elevation: 4,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    incident.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    incident.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(incident.category),
                        backgroundColor: Colors.blue.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(incident.status.name.toUpperCase()),
                        backgroundColor: _getStatusColor(incident.status),
                      ),
                    ],
                  ),
                  if (incident.images.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: incident.images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                incident.images[index],
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return Colors.red.withOpacity(0.2);
      case IncidentStatus.inProgress:
        return Colors.orange.withOpacity(0.2);
      case IncidentStatus.resolved:
        return Colors.green.withOpacity(0.2);
    }
  }
}

// Full screen details widget for reports list
class IncidentDetails extends StatefulWidget {
  final Incident incident;

  const IncidentDetails({
    super.key,
    required this.incident,
  });

  @override
  State<IncidentDetails> createState() => _IncidentDetailsState();
}

class _IncidentDetailsState extends State<IncidentDetails> {
  bool _isLoading = true;
  bool _canEdit = false;
  Timer? _refreshTimer;
  late Incident _incident;
  String? _reporterName;
  String? _inProgressName;
  String? _resolvedName;

  @override
  void initState() {
    super.initState();
    _incident = widget.incident;
    _checkEditPermission();
    _fetchUserNames();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEditPermission() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserFirebaseId = authService.currentUser?.firebaseId;
    setState(() {
      _canEdit = (_incident.reporterId.toString() == currentUserFirebaseId?.toString());
      _isLoading = false;
    });
  }

  Future<void> _fetchUserNames() async {
    Future<String?> fetchName(String? userId) async {
      if (userId == null || userId.isEmpty) return null;
      try {
        final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/users/by-firebase-id/$userId'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          // Prefer displayName, then email, then fallback to 'Unknown User'
          return (data['displayName'] != null && data['displayName'].toString().trim().isNotEmpty)
              ? data['displayName']
              : (data['email'] != null && data['email'].toString().trim().isNotEmpty)
                  ? data['email']
                  : 'Unknown User';
        }
      } catch (_) {}
      return 'Unknown User';
    }
    final names = await Future.wait([
      fetchName(_incident.reporterId),
      fetchName(_incident.inProgressBy),
      fetchName(_incident.resolvedBy),
    ]);
    if (mounted) {
      setState(() {
        _reporterName = names[0];
        _inProgressName = names[1];
        _resolvedName = names[2];
      });
    }
  }

  Future<void> _refreshIncident() async {
    setState(() => _isLoading = true);
    try {
      final updatedIncident = await Provider.of<IncidentService>(context, listen: false)
          .fetchIncidentById(_incident.id);
      if (mounted) {
        setState(() {
          _incident = updatedIncident;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing incident: $e'), backgroundColor: Colors.red, duration: Duration(seconds: 6)),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'medical':
        return Icons.medical_services;
      case 'police':
        return Icons.local_police;
      default:
        return Icons.report;
    }
  }

  void _updateStatus(IncidentStatus status) async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<IncidentService>(context, listen: false)
          .updateIncidentStatus(_incident.id, status, context: context);
      final updatedIncident = await Provider.of<IncidentService>(context, listen: false)
          .fetchIncidentById(_incident.id);
      if (mounted) {
        setState(() {
          _incident = updatedIncident;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${status.name}'), backgroundColor: Colors.green, duration: Duration(seconds: 4)),
        );
        Navigator.pop(context, true); // Notify parent to refresh
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red, duration: Duration(seconds: 6)),
        );
      }
    }
  }

  void _editIncident() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditIncidentScreen(incident: _incident),
      ),
    );
    if (result == true) {
      _refreshIncident();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isOfficer = authService.currentUser?.role == 'officer';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editIncident,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshIncident,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_incident.images.isNotEmpty)
                      SizedBox(
                        height: 250,
                        child: PageView.builder(
                          itemCount: _incident.images.length,
                          itemBuilder: (context, index) {
                            return Hero(
                              tag: 'incident-image-${_incident.id}-$index',
                              child: GestureDetector(
                                onTap: () => _showImageFullscreen(index),
                                child: Image.network(
                                  _incident.images[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getCategoryIcon(_incident.category),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _incident.title,
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                              ),
                              _buildStatusChip(_incident.status),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_incident.description),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoTile(
                                          context,
                                          'Category',
                                          _incident.category,
                                          _getCategoryIcon(_incident.category),
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildInfoTile(
                                          context,
                                          'Priority',
                                          _incident.priority.name,
                                          _getPriorityIcon(_incident.priority),
                                          color: _getPriorityColor(_incident.priority),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Location',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_incident.address),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: FlutterMap(
                                        options: MapOptions(
                                          center: _incident.latLng, // Use LatLng
                                          zoom: 15,
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName: 'com.safety.community_dashboard',
                                          ),
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: _incident.latLng, // Use LatLng
                                                width: 40,
                                                height: 40,
                                                child: const Icon(
                                                  Icons.location_on,
                                                  color: Colors.red,
                                                  size: 40,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Timeline',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTimelineItem(
                                    'Reported',
                                    _incident.createdAt,
                                    _reporterName ?? _incident.reporterId ?? 'N/A',
                                    Icons.flag,
                                    Colors.blue,
                                  ),
                                  if (_incident.inProgressAt != null)
                                    _buildTimelineItem(
                                      'In Progress',
                                      _incident.inProgressAt!,
                                      _inProgressName ?? _incident.inProgressBy ?? 'N/A',
                                      Icons.engineering,
                                      Colors.orange,
                                    ),
                                  if (_incident.resolvedAt != null)
                                    _buildTimelineItem(
                                      'Resolved',
                                      _incident.resolvedAt!,
                                      _resolvedName ?? _incident.resolvedBy ?? 'N/A',
                                      Icons.check_circle,
                                      Colors.green,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: isOfficer && !_isLoading && _incident.status != IncidentStatus.resolved
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_incident.status != IncidentStatus.inProgress)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.engineering),
                      label: const Text('Mark In Progress'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      onPressed: () => _updateStatus(IncidentStatus.inProgress),
                    ),
                  if (_incident.status != IncidentStatus.resolved)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark Resolved'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => _updateStatus(IncidentStatus.resolved),
                    ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String title,
    DateTime timestamp,
    String user,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'By $user',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _formatDate(timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageFullscreen(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          backgroundColor: Colors.black,
          body: PageView.builder(
            itemCount: _incident.images.length,
            controller: PageController(initialPage: initialIndex),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Hero(
                    tag: 'incident-image-${_incident.id}-$index',
                    child: Image.network(
                      _incident.images[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return Colors.red.withOpacity(0.2);
      case IncidentStatus.inProgress:
        return Colors.orange.withOpacity(0.2);
      case IncidentStatus.resolved:
        return Colors.green.withOpacity(0.2);
    }
  }

  Color _getPriorityColor(IncidentPriority priority) {
    switch (priority) {
      case IncidentPriority.high:
        return Colors.red.withOpacity(0.2);
      case IncidentPriority.medium:
        return Colors.orange.withOpacity(0.2);
      case IncidentPriority.low:
        return Colors.green.withOpacity(0.2);
    }
  }

  Widget _buildStatusChip(IncidentStatus status) {
    return Chip(
      avatar: Icon(
        _getStatusIcon(status),
        size: 18,
        color: _getStatusColor(status),
      ),
      label: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: _getStatusColor(status)),
      ),
      backgroundColor: _getStatusColor(status).withOpacity(0.1),
    );
  }

  IconData _getStatusIcon(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return Icons.error_outline;
      case IncidentStatus.inProgress:
        return Icons.pending_outlined;
      case IncidentStatus.resolved:
        return Icons.check_circle_outline;
    }
  }

  IconData _getPriorityIcon(IncidentPriority priority) {
    switch (priority) {
      case IncidentPriority.high:
        return Icons.warning;
      case IncidentPriority.medium:
        return Icons.info;
      case IncidentPriority.low:
        return Icons.circle;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
