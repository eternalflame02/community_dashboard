import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/incident.dart';
import '../../services/incident_service.dart';
import '../../services/auth_service.dart';

class IncidentDetails extends StatelessWidget {
  final Incident incident;
  final _incidentService = IncidentService();

  IncidentDetails({super.key, required this.incident});

  Future<void> _updateStatus(BuildContext context, IncidentStatus newStatus) async {
    try {
      await _incidentService.updateIncidentStatus(incident.id, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final isReporter = user?.uid == incident.reporterId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          if (isReporter)
            PopupMenuButton<IncidentStatus>(
              onSelected: (status) => _updateStatus(context, status),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (incident.images.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  viewportFraction: 1.0,
                  enableInfiniteScroll: false,
                ),
                items: incident.images.map((url) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  );
                }).toList(),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          incident.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      _PriorityBadge(priority: incident.priority),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _StatusBadge(status: incident.status),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.category,
                    label: 'Category',
                    value: incident.category,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: incident.address,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.access_time,
                    label: 'Reported',
                    value: DateFormat.yMMMd().add_jm().format(incident.createdAt),
                  ),
                  if (incident.resolvedAt != null) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.check_circle,
                      label: 'Resolved',
                      value: DateFormat.yMMMd()
                          .add_jm()
                          .format(incident.resolvedAt!),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    incident.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final IncidentPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case IncidentPriority.high:
        color = Theme.of(context).colorScheme.error;
      case IncidentPriority.medium:
        color = Colors.orange;
      case IncidentPriority.low:
        color = Colors.yellow.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IncidentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case IncidentStatus.open:
        color = Theme.of(context).colorScheme.error;
        icon = Icons.error_outline;
      case IncidentStatus.inProgress:
        color = Theme.of(context).colorScheme.primary;
        icon = Icons.pending;
      case IncidentStatus.resolved:
        color = Colors.green;
        icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}