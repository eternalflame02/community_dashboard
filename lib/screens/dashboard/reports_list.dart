import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/incident_service.dart';
import '../../models/incident.dart';
import '../dashboard/incident_details.dart';

class ReportsList extends StatefulWidget {
  const ReportsList({super.key});

  @override
  State<ReportsList> createState() => _ReportsListState();
}

class _ReportsListState extends State<ReportsList> {
  final ScrollController _scrollController = ScrollController();
  final List<Incident> _incidents = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final int _limit = 10;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _fetchMoreIncidents();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent && !_isLoading) {
        _fetchMoreIncidents();
      }
    });
  }

  Future<void> _fetchMoreIncidents() async {
    setState(() => _isLoading = true);
    try {
      final newIncidents = await Provider.of<IncidentService>(context, listen: false)
          .fetchIncidents(page: _currentPage, limit: _limit);
      setState(() {
        _incidents.addAll(newIncidents);
        _currentPage++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading incidents: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredIncidents = _incidents.where((incident) => incident.status != IncidentStatus.resolved).toList();

    return Column(
      children: [
        ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              _showCompleted = !_showCompleted;
            });
          },
          children: [
            ExpansionPanel(
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  title: const Text('Completed Reports'),
                );
              },
              body: Column(
                children: _incidents
                    .where((incident) => incident.status == IncidentStatus.resolved)
                    .map((incident) => ListTile(
                          title: Text(incident.title),
                          subtitle: Text(incident.description),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IncidentDetails(incident: incident),
                              ),
                            );
                          },
                        ))
                    .toList(),
              ),
              isExpanded: _showCompleted,
            ),
          ],
        ),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            itemCount: filteredIncidents.length + (_isLoading ? 1 : 0),
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              if (index == filteredIncidents.length) {
                return const Center(child: CircularProgressIndicator());
              }

              final incident = filteredIncidents[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: incident.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.photo_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                  title: Text(
                    incident.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    incident.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
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
            },
          ),
        ),
      ],
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}