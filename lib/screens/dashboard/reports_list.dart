import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/incident.dart';
import '../../services/incident_service.dart';
import 'incident_details.dart';  // Added import

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
      // Deduplicate by incident ID
      final existingIds = _incidents.map((e) => e.id).toSet();
      final uniqueNewIncidents = newIncidents.where((incident) => !existingIds.contains(incident.id)).toList();
      setState(() {
        _incidents.addAll(uniqueNewIncidents);
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
          child: _isLoading && _incidents.isEmpty
              ? ListView.separated(
                  itemCount: 6,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : filteredIncidents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200], // Changed from gradient blue to neutral grey
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Icon(Icons.inbox, size: 64, color: Colors.grey[500]), // Changed icon color to match neutral background
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No incidents to display',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All clear! No reports at the moment.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      itemCount: filteredIncidents.length + (_isLoading ? 1 : 0),
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        if (index == filteredIncidents.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        final incident = filteredIncidents[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeIn,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            color: Color.fromARGB(
                              (0.7 * 255).toInt(),
                              Colors.white.red,
                              Colors.white.green,
                              Colors.white.blue,
                            ),
                            shadowColor: Colors.black.withOpacity(0.12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => IncidentDetails(incident: incident),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (incident.images.isNotEmpty)
                                    Tooltip(
                                      message: 'Tap to view details',
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                        child: AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: Image.network(
                                            incident.images.first,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[200],
                                              child: const Center(child: Icon(Icons.broken_image)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                incident.title,
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Tooltip(
                                              message: 'Status: ${incident.status.name}',
                                              child: _buildStatusChip(context, incident.status),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          incident.description,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              Tooltip(
                                                message: 'Category: ${incident.category}',
                                                child: _buildCategoryChip(context, incident.category),
                                              ),
                                              const SizedBox(width: 8),
                                              Tooltip(
                                                message: 'Priority: ${incident.priority.name}',
                                                child: _buildPriorityChip(context, incident.priority),
                                              ),
                                              const SizedBox(width: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF4F8EFF)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatDate(incident.createdAt),
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                                                  ),
                                                ],
                                              ),
                                              if (incident.status != IncidentStatus.resolved)
                                                IconButton(
                                                  tooltip: 'Mark as resolved',
                                                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                                  onPressed: () => _confirmMarkAsResolved(context, incident),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, IncidentStatus status) {
    Color color;
    IconData icon;
    switch (status) {
      case IncidentStatus.open:
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      case IncidentStatus.inProgress:
        color = Colors.orange;
        icon = Icons.pending_outlined;
        break;
      case IncidentStatus.resolved:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
    }
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(status.name.toUpperCase()),
      backgroundColor: color.withOpacity(0.9),
      labelStyle: TextStyle(color: color),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String category) {
    return Chip(
      label: Text(category),
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
    );
  }

  Widget _buildPriorityChip(BuildContext context, IncidentPriority priority) {
    Color color;
    switch (priority) {
      case IncidentPriority.high:
        color = Colors.red;
        break;
      case IncidentPriority.medium:
        color = Colors.orange;
        break;
      case IncidentPriority.low:
        color = Colors.green;
        break;
    }
    return Chip(
      label: Text(priority.name.toUpperCase()),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  Future<void> _confirmMarkAsResolved(BuildContext context, Incident incident) async {
    final shouldResolve = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Resolved'),
        content: const Text('Are you sure you want to mark this incident as resolved?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark as Resolved'),
          ),
        ],
      ),
    );
    if (shouldResolve == true) {
      _markAsResolved(context, incident);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}