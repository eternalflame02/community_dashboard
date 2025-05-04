import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:shimmer/shimmer.dart';
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
  bool _mapControllerDisposed = false;
  Position? _currentPosition;
  final double _currentZoom = 15.0;
  Incident? _selectedIncident;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapControllerDisposed = true;
    _mapController.dispose();
    super.dispose();
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

      // Use high accuracy mode always
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        // Only move the map if the controller is attached and widget is mounted and not disposed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_mapControllerDisposed) {
            try {
              _mapController.move(
                LatLng(position.latitude, position.longitude),
                _currentZoom,
              );
            } catch (_) {}
          }
        });
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
        return const Color.fromARGB(255, 10, 210, 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Incident>>(
      future: Provider.of<IncidentService>(context, listen: false).fetchIncidents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Shimmer loading effect
          return ListView.separated(
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Failed to load incidents', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('${snapshot.error}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red[400])),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => setState(() {}),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Show the map even if there are no incidents
          List<Marker> markers = [];
          if (_currentPosition != null) {
            markers.add(
              Marker(
                point: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha((0.7 * 255).round()),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: const Tooltip(
                    message: 'Your current location',
                    child: Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            );
          }
          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(0, 0),
              initialZoom: _currentPosition != null ? _currentZoom : 2,
              onTap: (_, __) => setState(() => _selectedIncident = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: [],
                userAgentPackageName: 'com.safety.community_dashboard',
                tileProvider: CancellableNetworkTileProvider(),
                retinaMode: true,
              ),
              MarkerLayer(markers: markers),
            ],
          );
        }

        final incidents = snapshot.data!;
        List<Marker> markers = [];

        // Add incident markers
        for (var incident in incidents) {
          if (incident.status != IncidentStatus.resolved &&
              incident.location['coordinates'] != null &&
              incident.location['coordinates'].length == 2) {
            markers.add(
              Marker(
                point: incident.latLng,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIncident = incident),
                  child: Tooltip(
                    message: 'Priority: ${incident.priority.name}\nTap to view details',
                    child: Icon(
                      Icons.location_on,
                      color: _getPriorityColor(incident.priority),
                      size: 40,
                    ),
                  ),
                ),
              ),
            );
          }
        }

        // Add current location marker
        if (_currentPosition != null) {
          markers.add(
            Marker(
              point: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha((0.7 * 255).round()),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: const Tooltip(
                  message: 'Your current location',
                  child: Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          );
        }

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition != null
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : const LatLng(0, 0),
            initialZoom: _currentPosition != null ? _currentZoom : 2,
            onTap: (_, __) => setState(() => _selectedIncident = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: [],
              userAgentPackageName: 'com.safety.community_dashboard',
              tileProvider: CancellableNetworkTileProvider(),
              retinaMode: true,
            ),
            MarkerLayer(markers: markers),
            if (_selectedIncident != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.2, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: IncidentDetailsPopup(
                  key: ValueKey(_selectedIncident!.id),
                  incident: _selectedIncident!,
                ),
              ),
          ],
        );
      },
    );
  }
}