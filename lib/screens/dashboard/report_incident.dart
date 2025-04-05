import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/incident_service.dart';
import '../../models/incident.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapController = MapController();
  final _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  LatLng? _selectedLocation;
  List<XFile> _selectedImages = [];
  String _category = 'Other';
  IncidentPriority _priority = IncidentPriority.medium;

  final List<String> _categories = [
    'Infrastructure',
    'Safety',
    'Environmental',
    'Traffic',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Delay getting location to avoid build issues
    Future.microtask(_getCurrentLocation);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      if (_mapController.camera.center != _selectedLocation) {
        _mapController.move(_selectedLocation!, 15);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<List<String>> _uploadImages() async {
    final List<String> urls = [];
    final storage = FirebaseStorage.instance;

    for (final image in _selectedImages) {
      final ref = storage.ref().child(
        'incidents/${DateTime.now().millisecondsSinceEpoch}_${image.name}',
      );

      final uploadTask = await ref.putData(
        await image.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await uploadTask.ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrls = await _uploadImages();

      final incident = Incident(
        id: '',  // Will be set by Firestore
        title: _titleController.text,
        description: _descriptionController.text,
        location: GeoPoint(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        ),
        address: _addressController.text.isEmpty 
            ? 'Location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}'
            : _addressController.text,
        category: _category,
        priority: _priority,
        status: IncidentStatus.open,
        reporterId: 'anonymous', // TODO: Add auth
        images: imageUrls,
        createdAt: DateTime.now(),
      );

      await Provider.of<IncidentService>(context, listen: false)
          .createIncident(incident);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident reported successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _selectedLocation ?? const LatLng(0, 0),
                                initialZoom: _selectedLocation != null ? 15 : 2,
                                onTap: (_, point) {
                                  setState(() => _selectedLocation = point);
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.community_dashboard',
                                ),
                                if (_selectedLocation != null)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        width: 40,
                                        height: 40,
                                        point: _selectedLocation!,
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Tap on the map to set location',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.my_location),
                                  onPressed: _getCurrentLocation,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _category = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<IncidentPriority>(
                      value: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: IncidentPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _priority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Add Photos'),
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedImages.length} photos selected',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitReport,
                      child: const Text('Submit Report'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}