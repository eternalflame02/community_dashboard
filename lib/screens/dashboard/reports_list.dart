import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/incident_service.dart';
import '../../models/incident.dart';
import '../dashboard/incident_details.dart';

class ReportsList extends StatelessWidget {
  final IncidentStatus? filterStatus;

  const ReportsList({
    super.key,
    this.filterStatus,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Incident>>(
      future: Provider.of<IncidentService>(context, listen: false).fetchIncidents(),
      builder: (context, snapshot) {
        debugPrint('Snapshot state: ${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          debugPrint('Error in FutureBuilder: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          debugPrint('No incidents found.');
          return const Center(child: Text('No incidents found.'));
        }

        final incidents = snapshot.data!;
        debugPrint('Fetched ${incidents.length} incidents.');

        return ListView.builder(
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final incident = incidents[index];
            return ListTile(
              leading: incident.images.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        incident.images.first,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.photo_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
              title: Text(incident.title),
              subtitle: Text(incident.description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(incident.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getPriorityColor(incident.priority),
                      ),
                    ),
                    child: Text(
                      incident.priority.name.toUpperCase(),
                      style: TextStyle(
                        color: _getPriorityColor(incident.priority),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      incident.status == IncidentStatus.resolved
                          ? Icons.check_circle
                          : Icons.hourglass_empty,
                      color: incident.status == IncidentStatus.resolved
                          ? Colors.green
                          : Colors.orange,
                    ),
                    onPressed: () => _markAsResolved(context, incident),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IncidentDetails(incident: incident),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _markAsResolved(BuildContext context, Incident incident) async {
    try {
      final incidentService =
          Provider.of<IncidentService>(context, listen: false);
      await incidentService.updateIncidentStatus(
        incident.id,
        IncidentStatus.resolved,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident marked as resolved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
      case IncidentPriority.low:
        return Colors.green;
      case IncidentPriority.medium:
        return Colors.orange;
      case IncidentPriority.high:
        return Colors.red;
    }
  }
}