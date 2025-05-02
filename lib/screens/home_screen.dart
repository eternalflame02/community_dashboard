import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'dashboard/incidents_map.dart';
import 'dashboard/reports_list.dart';
import 'dashboard/profile_screen.dart';
import 'dashboard/report_incident.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Add a GlobalKey for ReportsList
  final GlobalKey<ReportsListState> _reportsListKey = GlobalKey<ReportsListState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const IncidentsMap(),
      ReportsList(key: _reportsListKey),
      const ProfileScreen(),
    ];
  }

  Future<void> _showReportIncident() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReportIncidentScreen(),
        fullscreenDialog: true,
      ),
    );
    // If a report was submitted and we're on the Reports page, refresh it
    if (result == true && _selectedIndex == 1) {
      _reportsListKey.currentState?.refresh();
    }
  }

  void _showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      context.read<AuthService>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        title: const Text('Community Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _showLogoutConfirmation,
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.map),
                  label: Text('Map'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.list),
                  label: Text('Reports'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: Padding(
                key: ValueKey<int>(_selectedIndex),
                padding: isDesktop
                    ? const EdgeInsets.symmetric(horizontal: 32, vertical: 24)
                    : const EdgeInsets.all(8.0),
                child: _pages[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1)
          ? Tooltip(
              message: 'Report a new incident',
              child: AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 200),
                child: FloatingActionButton.extended(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  onPressed: _showReportIncident,
                  icon: const Icon(Icons.add),
                  label: const Text('Report'),
                ),
              ),
            )
          : null,
      bottomNavigationBar: isDesktop
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: NavigationBar(
                  height: 60,
                  backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.map),
                      label: 'Map',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.list),
                      label: 'Reports',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}