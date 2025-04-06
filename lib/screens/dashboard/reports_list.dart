import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/incident_service.dart';
import '../../models/incident.dart';

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
              title: Text(incident.title),
              subtitle: Text(incident.description),
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
}