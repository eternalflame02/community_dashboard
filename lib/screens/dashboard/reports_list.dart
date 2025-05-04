import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/incident.dart';
import '../../services/incident_service.dart';
import '../../services/auth_service.dart'; // Added import
import 'incident_details.dart';

class ReportsList extends StatefulWidget {
  final bool sortByPriority;
  const ReportsList({super.key, this.sortByPriority = false});

  @override
  State<ReportsList> createState() => ReportsListState();
}

class ReportsListState extends State<ReportsList> {
  final ScrollController _scrollController = ScrollController();
  final List<Incident> _incidents = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final int _limit = 10;
  bool _showCompleted = false;
  int _selectedStatusIndex = 0; // 0: Open, 1: In Progress, 2: Resolved
  int _segmentedStatus = 0; // 0: Open, 1: In Progress, 2: Resolved
  int _dropdownStatus = 0; // 0: Open, 1: In Progress, 2: Resolved
  int _sideNavStatus = 0; // 0: Open, 1: In Progress, 2: Resolved

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always refresh the list when the page is shown
    refresh();
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
          SnackBar(content: Text('Error loading incidents: $e'), backgroundColor: Colors.red, duration: Duration(seconds: 6)),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Add a public refresh method
  void refresh() {
    setState(() {
      _incidents.clear();
      _currentPage = 1;
    });
    _fetchMoreIncidents();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isOfficer = authService.currentUser?.role == 'officer';
    final theme = Theme.of(context);

    // Group incidents by status for color/icon
    final statusLabels = ['Open', 'In Progress', 'Resolved'];
    final statusColors = [Colors.red, Colors.orange, Colors.green];
    final statusIcons = [Icons.error_outline, Icons.pending_outlined, Icons.check_circle_outline];

    // All incidents, sorted by status then date
    final allIncidents = [
      ..._incidents.where((i) => i.status == IncidentStatus.open).map((i) => {'incident': i, 'status': 0}),
      ..._incidents.where((i) => i.status == IncidentStatus.inProgress).map((i) => {'incident': i, 'status': 1}),
      ..._incidents.where((i) => i.status == IncidentStatus.resolved).map((i) => {'incident': i, 'status': 2}),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: MasonryGridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : MediaQuery.of(context).size.width > 600 ? 3 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: allIncidents.length,
          itemBuilder: (context, index) {
            final map = allIncidents[index];
            final incident = map['incident'] as Incident;
            final statusIdx = map['status'] as int;
            return Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              color: theme.cardColor,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IncidentDetails(incident: incident),
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      _incidents.clear();
                      _currentPage = 1;
                    });
                    _fetchMoreIncidents();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: statusColors[statusIdx],
                            child: Icon(statusIcons[statusIdx], color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              statusLabels[statusIdx],
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: statusColors[statusIdx],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        incident.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        incident.description,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (incident.images.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            incident.images.first,
                            height: 120 + (index % 3) * 30.0, // Vary height for masonry effect
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              height: 120,
                              child: const Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(_formatDate(incident.createdAt), style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                          const Spacer(),
                          Icon(Icons.category, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(incident.category, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ReportTile extends StatefulWidget {
  final Incident incident;
  final bool isOfficer;
  final VoidCallback onTap;

  const _ReportTile({
    required this.incident,
    required this.isOfficer,
    required this.onTap,
  });

  @override
  State<_ReportTile> createState() => _ReportTileState();
}

class _ReportTileState extends State<_ReportTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: _hovering ? 1.04 : 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, scale, child) => Opacity(
        opacity: 1,
        child: Transform.scale(
          scale: scale,
          child: child,
        ),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: _hovering ? 18 : 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.surface.withOpacity(0.85)
                : Colors.white.withOpacity(0.7),
            shadowColor: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.incident.images.isNotEmpty)
                  Tooltip(
                    message: 'Tap to view details',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          widget.incident.images.first,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: theme.brightness == Brightness.dark ? theme.colorScheme.surfaceVariant : Colors.grey[200],
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
                              widget.incident.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Tooltip(
                            message: 'Status: ${widget.incident.status.name}',
                            child: _buildStatusChip(context, widget.incident.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.incident.description,
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
                              message: 'Category: ${widget.incident.category}',
                              child: _buildCategoryChip(context, widget.incident.category),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Priority: ${widget.incident.priority.name}',
                              child: _buildPriorityChip(context, widget.incident.priority),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF4F8EFF)),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(widget.incident.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                                ),
                              ],
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
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, IncidentStatus status) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
      backgroundColor: isDark ? color.withOpacity(0.25) : color.withOpacity(0.9),
      labelStyle: TextStyle(color: isDark ? color : color),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String category) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Chip(
      label: Text(category),
      backgroundColor: isDark
          ? theme.colorScheme.primary.withOpacity(0.18)
          : theme.colorScheme.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isDark ? theme.colorScheme.primary : theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildPriorityChip(BuildContext context, IncidentPriority priority) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
      backgroundColor: isDark ? color.withOpacity(0.18) : color.withOpacity(0.1),
      labelStyle: TextStyle(color: isDark ? color : color),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}