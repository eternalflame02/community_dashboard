import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/incident.dart';
import '../../services/incident_service.dart';
import 'package:provider/provider.dart';

class IncidentDetails extends StatelessWidget {
  final Incident incident;

  const IncidentDetails({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
      ),
      body: SingleChildScrollView(
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
                      incident.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      incident.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status: ${incident.status.name.toUpperCase()}',
                      style: TextStyle(
                        color: _getStatusColor(incident.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Location: ${incident.address}'),
                    const SizedBox(height: 8),
                    Text('Category: ${incident.category}'),
                    const SizedBox(height: 8),
                    Text(
                      'Priority: ${incident.priority.name.toUpperCase()}',
                      style: TextStyle(
                        color: _getPriorityColor(incident.priority),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Updated to decode and display Base64-encoded images
                    if (incident.images.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: incident.images.length,
                          itemBuilder: (context, index) {
                            final imageBytes = base64Decode(incident.images[index]);
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                                width: 200,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (incident.status != IncidentStatus.resolved)
              ElevatedButton(
                onPressed: () => _updateStatus(context),
                child: Text(
                  incident.status == IncidentStatus.open
                      ? 'Mark In Progress'
                      : 'Mark Resolved',
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
        return Colors.red;
      case IncidentStatus.inProgress:
        return Colors.orange;
      case IncidentStatus.resolved:
        return Colors.green;
    }
  }

  Color _getPriorityColor(IncidentPriority priority) {
    switch (priority) {
      case IncidentPriority.high:
        return Colors.red;
      case IncidentPriority.medium:
        return Colors.orange;
      case IncidentPriority.low:
        return Colors.yellow.shade800;
    }
  }

  Future<void> _updateStatus(BuildContext context) async {
    try {
      final service = Provider.of<IncidentService>(context, listen: false);
      final newStatus = incident.status == IncidentStatus.open
          ? IncidentStatus.inProgress
          : IncidentStatus.resolved;
      
      await service.updateIncidentStatus(incident.id, newStatus);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.name}'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }
}