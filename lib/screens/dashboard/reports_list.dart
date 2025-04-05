import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/incident_service.dart';
import '../../models/incident.dart';

class ReportsList extends StatelessWidget {
  const ReportsList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Incident>>(
      stream: Provider.of<IncidentService>(context).getIncidents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final incidents = snapshot.data ?? [];

        if (incidents.isEmpty) {
          return const Center(
            child: Text('No incidents reported yet'),
          );
        }

        return ListView.builder(
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final incident = incidents[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(incident.title),
                subtitle: Text(incident.description),
                trailing: _buildStatusChip(incident.status),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(IncidentStatus status) {
    Color color;
    switch (status) {
      case IncidentStatus.open:
        color = Colors.red;
        break;
      case IncidentStatus.inProgress:
        color = Colors.orange;
        break;
      case IncidentStatus.resolved:
        color = Colors.green;
        break;
    }

    return Chip(
      label: Text(
        status.name.toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}