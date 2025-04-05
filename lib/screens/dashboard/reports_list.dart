import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import '../../models/incident.dart';
import '../../services/incident_service.dart';
import '../../providers/incidents_provider.dart';
import 'package:intl/intl.dart';
import 'incident_details.dart';

class ReportsList extends StatefulWidget {
  const ReportsList({super.key});

  @override
  State<ReportsList> createState() => _ReportsListState();
}

class _ReportsListState extends State<ReportsList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidentsProvider = Provider.of<IncidentsProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search incidents...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  incidentsProvider.setSearchQuery('');
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => incidentsProvider.setSearchQuery(value),
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Open'),
                    Tab(text: 'Resolved'),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
                  onTap: (index) {
                    switch (index) {
                      case 0:
                        incidentsProvider.setFilterStatus(null);
                        break;
                      case 1:
                        incidentsProvider.setFilterStatus(IncidentStatus.open);
                        break;
                      case 2:
                        incidentsProvider.setFilterStatus(IncidentStatus.resolved);
                        break;
                    }
                  },
                ),
                Expanded(
                  child: StreamBuilder<List<Incident>>(
                    stream: incidentsProvider.incidentsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final incidents = snapshot.data!;
                      if (incidents.isEmpty) {
                        return const Center(
                          child: Text('No incidents reported'),
                        );
                      }

                      final filteredIncidents = incidents.where((incident) {
                        if (incidentsProvider.searchQuery.isNotEmpty) {
                          final query = incidentsProvider.searchQuery.toLowerCase();
                          if (!incident.title.toLowerCase().contains(query) &&
                              !incident.description.toLowerCase().contains(query) &&
                              !incident.address.toLowerCase().contains(query)) {
                            return false;
                          }
                        }

                        if (incidentsProvider.filterCategory.isNotEmpty &&
                            incident.category.toLowerCase() !=
                                incidentsProvider.filterCategory.toLowerCase()) {
                          return false;
                        }

                        if (incidentsProvider.filterStatus != null &&
                            incident.status != incidentsProvider.filterStatus) {
                          return false;
                        }

                        if (incidentsProvider.filterPriority != null &&
                            incident.priority != incidentsProvider.filterPriority) {
                          return false;
                        }

                        return true;
                      }).toList();

                      if (filteredIncidents.isEmpty) {
                        return const Center(
                          child: Text('No matching incidents found'),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: filteredIncidents.length,
                        itemBuilder: (context, index) {
                          final incident = filteredIncidents[index];
                          return _IncidentListItem(incident: incident);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IncidentListItem extends StatelessWidget {
  final Incident incident;

  const _IncidentListItem({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: incident.images.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: CachedNetworkImage(
                  imageUrl: incident.images.first,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Icon(
                  _getCategoryIcon(incident.category),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
        title: Text(incident.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${incident.address}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getPriorityIcon(incident.priority),
                  size: 16,
                  color: _getPriorityColor(context, incident.priority),
                ),
                const SizedBox(width: 4),
                Text(incident.priority.name.toUpperCase()),
                const SizedBox(width: 8),
                Icon(
                  _getStatusIcon(incident.status),
                  size: 16,
                  color: _getStatusColor(context, incident.status),
                ),
                const SizedBox(width: 4),
                Text(_getStatusText(incident.status)),
              ],
            ),
            Text(
              'Reported: ${DateFormat.yMMMd().format(incident.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
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
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return MdiIcons.roadVariant;
      case 'safety':
        return MdiIcons.shieldAlert;
      case 'environmental':
        return MdiIcons.tree;
      case 'traffic':
        return MdiIcons.car;
      default:
        return MdiIcons.alert;
    }
  }

  IconData _getPriorityIcon(IncidentPriority priority) {
    switch (priority) {
      case IncidentPriority.high:
        return MdiIcons.alertCircle;
      case IncidentPriority.medium:
        return MdiIcons.alertOctagon;
      case IncidentPriority.low:
        return MdiIcons.alertOutline;
    }
  }

  Color _getPriorityColor(BuildContext context, IncidentPriority priority) {
    switch (priority) {
      case IncidentPriority.high:
        return Theme.of(context).colorScheme.error;
      case IncidentPriority.medium:
        return Colors.orange;
      case IncidentPriority.low:
        return Colors.yellow.shade800;
    }
  }

  IconData _getStatusIcon(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return MdiIcons.folderOpen;
      case IncidentStatus.inProgress:
        return MdiIcons.clockOutline;
      case IncidentStatus.resolved:
        return MdiIcons.checkCircle;
    }
  }

  Color _getStatusColor(BuildContext context, IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return Theme.of(context).colorScheme.error;
      case IncidentStatus.inProgress:
        return Theme.of(context).colorScheme.primary;
      case IncidentStatus.resolved:
        return Colors.green;
    }
  }

  String _getStatusText(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return 'Open';
      case IncidentStatus.inProgress:
        return 'In Progress';
      case IncidentStatus.resolved:
        return 'Resolved';
    }
  }
}