import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/foundation.dart';
import '../../models/incident.dart';
import '../../services/incident_service.dart';
import '../../services/auth_service.dart'; // Added import
import 'incident_details.dart';
//import 'report_incident.dart'; // Import the ReportIncidentScreen class
import 'edit_incident_screen.dart'; // Import the EditIncidentScreen class

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
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    return Scaffold(
      body: Stack(
        children: [
          Column(
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
                    body: _incidents.where((incident) => incident.status == IncidentStatus.resolved).isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('No completed reports.'),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
                                  defaultTargetPlatform == TargetPlatform.macOS ||
                                  defaultTargetPlatform == TargetPlatform.linux;
                              final crossAxisCount = isDesktop
                                  ? (constraints.maxWidth ~/ 350).clamp(2, 5)
                                  : 1;
                              final completedIncidents = _incidents.where((incident) => incident.status == IncidentStatus.resolved).toList();
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: isDesktop ? 0.85 : 1.0,
                                ),
                                itemCount: completedIncidents.length,
                                itemBuilder: (context, index) {
                                  final incident = completedIncidents[index];
                                  return AbsorbPointer(
                                    absorbing: _isLoading,
                                    child: _ReportTile(
                                      incident: incident,
                                      isOfficer: isOfficer,
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => IncidentDetails(incident: incident),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
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
                    : _incidents.where((incident) => incident.status != IncidentStatus.resolved).toList().isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.brightness == Brightness.dark ? theme.colorScheme.surfaceVariant : Colors.grey[200],
                                  ),
                                  padding: const EdgeInsets.all(18),
                                  child: Icon(Icons.inbox, size: 64, color: theme.brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[500]),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No incidents to display',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.brightness == Brightness.dark ? Colors.grey[200] : Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'All clear! No reports at the moment.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = isDesktop
                                  ? (constraints.maxWidth ~/ 350).clamp(2, 5)
                                  : 1;
                              final incidents = _incidents.where((incident) => incident.status != IncidentStatus.resolved).toList();
                              return GridView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: isDesktop ? 0.85 : 1.0,
                                ),
                                itemCount: incidents.length,
                                itemBuilder: (context, index) {
                                  final incident = incidents[index];
                                  return AbsorbPointer(
                                    absorbing: _isLoading,
                                    child: _ReportTile(
                                      incident: incident,
                                      isOfficer: isOfficer,
                                      onTap: () async {
                                        final result = await Navigator.push(
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
                                        if (result == true) {
                                          setState(() {
                                            _incidents.clear();
                                            _currentPage = 1;
                                          });
                                          _fetchMoreIncidents();
                                        }
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
          if (_isLoading && _incidents.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
        ],
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