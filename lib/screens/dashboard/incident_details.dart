import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import '../../models/incident.dart';
import '../../services/incident_service.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    _incident = widget.incident;
    _checkEditPermission();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEditPermission() async {
    // Implement your logic to check if the user can edit the incident
    setState(() {
      _canEdit = true; // or false based on your logic
      _isLoading = false;
    });
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

        if (_incident.status != IncidentStatus.resolved) {
          final shouldContinue = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Continue to iterate?'),
              content: const Text('Would you like to keep monitoring this incident?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stop'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );

          if (shouldContinue == true) {
            _refreshTimer = Timer(const Duration(seconds: 30), _refreshIncident);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing incident: $e')),
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
          .updateIncidentStatus(_incident.id, status);
      final updatedIncident = await Provider.of<IncidentService>(context, listen: false)
          .fetchIncidentById(_incident.id);
      if (mounted) {
        setState(() {
          _incident = updatedIncident;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to \\${status.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: \\${e}')),
        );
      }
    }
  }

  void _editIncident() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit incident not implemented.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                              tag: 'incident-image-{_incident.id}-$index',
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
                                    'N/A',
                                    Icons.flag,
                                    Colors.blue,
                                  ),
                                  if (_incident.status != IncidentStatus.open)
                                    _buildTimelineItem(
                                      'In Progress',
                                      _incident.createdAt,
                                      'N/A',
                                      Icons.engineering,
                                      Colors.orange,
                                    ),
                                  if (_incident.status == IncidentStatus.resolved)
                                    _buildTimelineItem(
                                      'Resolved',
                                      _incident.resolvedAt ?? _incident.createdAt,
                                      'N/A',
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
      bottomNavigationBar: null,
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
    return '${date.day}/${date.month}/${date.year}';
  }
}