import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../models/incident.dart';
import '../../services/incident_service.dart';
import 'incident_details.dart';

class IncidentsMap extends StatefulWidget {
  const IncidentsMap({super.key});

  @override
  State<IncidentsMap> createState() => _IncidentsMapState();
}

class _IncidentsMapState extends State<IncidentsMap> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  final List<Marker> _markers = [];
  double _currentZoom = 15.0;
  Incident? _selectedIncident;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions permanently denied'),
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        _mapController.move(
          LatLng(position.latitude, position.longitude),
          _currentZoom,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Color _getPriorityColor(IncidentPriority priority) {
    switch (priority) {
      case IncidentPriority.high:
        return Colors.red;
      case IncidentPriority.medium:
        return Colors.orange;
      case IncidentPriority.low:
        return Colors.yellow.shade800;
    }
  }

  void _updateMarkers(List<Incident> incidents) {
    setState(() {
      _markers.clear();
      for (final incident in incidents) {
        _markers.add(
          Marker(
            width: 40,
            height: 40,
            point: incident.latLng,
            child: _CustomMarker(
              color: _getPriorityColor(incident.priority),
              isSelected: _selectedIncident?.id == incident.id,
              onTap: () => setState(() => _selectedIncident = incident),
            ),
          ),
        );
      }
    });
  }

  void _showIncidentDetails(BuildContext context, Incident incident) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncidentDetails(incident: incident),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incidentsService = Provider.of<IncidentService>(context);

    return Stack(
      children: [
        StreamBuilder<List<Incident>>(
          stream: incidentsService.getIncidents(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _updateMarkers(snapshot.data!);
            }

            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      )
                    : const LatLng(0, 0),
                initialZoom: _currentPosition != null ? _currentZoom : 2,
                onTap: (_, __) => setState(() => _selectedIncident = null),
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    setState(() {
                      _currentZoom = position.zoom ?? _currentZoom;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.safety.community_dashboard',
                ),
                MarkerLayer(markers: _markers),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search incidents...',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        incidentsService.setSearchQuery(value);
                      },
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list),
                    onSelected: (value) {
                      switch (value) {
                        case 'all':
                          incidentsService.clearFilters();
                          break;
                        case 'open':
                          incidentsService.setFilterStatus(IncidentStatus.open);
                          break;
                        case 'high_priority':
                          incidentsService
                              .setFilterPriority(IncidentPriority.high);
                          break;
                        case 'infrastructure':
                          incidentsService.setFilterCategory('Infrastructure');
                          break;
                        case 'safety':
                          incidentsService.setFilterCategory('Safety');
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'all',
                        child: Text('All Incidents'),
                      ),
                      const PopupMenuItem(
                        value: 'open',
                        child: Text('Open Issues'),
                      ),
                      const PopupMenuItem(
                        value: 'high_priority',
                        child: Text('High Priority'),
                      ),
                      const PopupMenuItem(
                        value: 'infrastructure',
                        child: Text('Infrastructure'),
                      ),
                      const PopupMenuItem(
                        value: 'safety',
                        child: Text('Safety'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Zoom controls
        Positioned(
          right: 16,
          bottom: 96,
          child: Card(
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final newZoom = _currentZoom + 1;
                    _mapController.move(
                      _mapController.camera.center,
                      newZoom,
                    );
                    setState(() => _currentZoom = newZoom);
                  },
                ),
                Container(
                  height: 1,
                  width: 24,
                  color: Colors.grey.withOpacity(0.3),
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    final newZoom = _currentZoom - 1;
                    _mapController.move(
                      _mapController.camera.center,
                      newZoom,
                    );
                    setState(() => _currentZoom = newZoom);
                  },
                ),
              ],
            ),
          ),
        ),
        // Location button
        Positioned(
          right: 16,
          bottom: 32,
          child: FloatingActionButton(
            heroTag: 'location_button',
            onPressed: _getCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
        ),
        if (incidentsService.filterCategory?.isNotEmpty == true ||
            incidentsService.filterPriority != null ||
            incidentsService.filterStatus != null ||
            incidentsService.searchQuery.isNotEmpty)
          Positioned(
            top: 80,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () => incidentsService.clearFilters(),
              child: const Icon(Icons.clear),
            ),
          ),
        // Preview panel
        if (_selectedIncident != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: _selectedIncident!.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              _selectedIncident!.images.first,
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
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.photo_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                    title: Text(_selectedIncident!.title),
                    subtitle: Text(
                      _selectedIncident!.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(_selectedIncident!.priority)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getPriorityColor(_selectedIncident!.priority),
                        ),
                      ),
                      child: Text(
                        _selectedIncident!.priority.name.toUpperCase(),
                        style: TextStyle(
                          color: _getPriorityColor(_selectedIncident!.priority),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _selectedIncident = null),
                          child: const Text('CLOSE'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _showIncidentDetails(
                            context,
                            _selectedIncident!,
                          ),
                          child: const Text('VIEW DETAILS'),
                        ),
                      ],
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

class _CustomMarker extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomMarker({
    required this.color,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Icon(
            Icons.location_on,
            color: color,
            size: 40,
          ),
          if (isSelected)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}