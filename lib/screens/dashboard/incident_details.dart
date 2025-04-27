import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/incident.dart';
import '../../services/incident_service.dart';
import 'package:provider/provider.dart';

// Popup widget for map view
class IncidentDetailsPopup extends StatelessWidget {
  final Incident incident;

  const IncidentDetailsPopup({
    super.key,
    required this.incident,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
  bool _isUpdating = false;

  Future<void> _updateStatus(IncidentStatus newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await Provider.of<IncidentService>(context, listen: false)
          .updateIncidentStatus(widget.incident.id, newStatus);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          PopupMenuButton<IncidentStatus>(
            onSelected: _updateStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: IncidentStatus.open,
                child: Text('Mark as Open'),
              ),
              const PopupMenuItem(
                value: IncidentStatus.inProgress,
                child: Text('Mark as In Progress'),
              ),
              const PopupMenuItem(
                value: IncidentStatus.resolved,
                child: Text('Mark as Resolved'),
              ),
            ],
          ),
        ],
      ),
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.incident.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Chip(
                                label: Text(widget.incident.category),
                                backgroundColor: Colors.blue.withOpacity(0.2),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(widget.incident.status.name.toUpperCase()),
                                backgroundColor: _getStatusColor(widget.incident.status),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(widget.incident.priority.name.toUpperCase()),
                                backgroundColor: _getPriorityColor(widget.incident.priority),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.incident.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: SizedBox(
                      height: 300,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: widget.incident.latLng,
                          initialZoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.safety.community_dashboard',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: widget.incident.latLng,
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.location_on,
                                  color: _getPriorityColor(widget.incident.priority),
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.incident.images.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Images',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.incident.images.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        widget.incident.images[index],
                                        fit: BoxFit.cover,
                                        width: 200,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Additional Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            title: const Text('Address'),
                            subtitle: Text(widget.incident.address),
                          ),
                          ListTile(
                            title: const Text('Reported By'),
                            subtitle: Text(widget.incident.reporterId),
                          ),
                          ListTile(
                            title: const Text('Reported On'),
                            subtitle: Text(widget.incident.createdAt.toString()),
                          ),
                          if (widget.incident.resolvedAt != null)
                            ListTile(
                              title: const Text('Resolved On'),
                              subtitle: Text(widget.incident.resolvedAt.toString()),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
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
}