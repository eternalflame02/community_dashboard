import 'package:flutter/material.dart';
import 'dashboard/incidents_map.dart';
import 'dashboard/reports_list.dart';

class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({super.key});

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.linux;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Dashboard'),
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
                  label: Text('Priority Reports'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                IncidentsMap(),
                _OfficerReportsList(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
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
                  label: 'Priority Reports',
                ),
              ],
            ),
    );
  }
}

class _OfficerReportsList extends StatelessWidget {
  const _OfficerReportsList();

  @override
  Widget build(BuildContext context) {
    // You can reuse ReportsList but sort by priority descending
    return ReportsList(
      sortByPriority: true,
    );
  }
}
