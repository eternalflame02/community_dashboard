import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../../services/incident_service.dart';
import '../../models/incident.dart';
import '../../services/auth_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

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
  late final MapController _mapController;
  final _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  LatLng? _selectedLocation;
  List<XFile> _selectedImages = [];
  String _category = 'Other';
  IncidentPriority _priority = IncidentPriority.medium;

  // Animation keys
  bool _showForm = false;

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
    _mapController = MapController();
    Future.microtask(_getCurrentLocation);
    // Show form with animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showForm = true);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Improved location accuracy by using high-accuracy mode
  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // Set high accuracy
      );
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      if (_selectedLocation != null) {
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Added option to capture image using the camera
  Future<void> _captureImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    }
  }

  Future<List<String>> _uploadImages() async {
    final List<String> imageUrls = [];
    for (final image in _selectedImages) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:3000/upload'),
      );
      
      final bytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: path.basename(image.path),
        ),
      );

      try {
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        debugPrint('Image upload response: $responseBody');
        
        if (response.statusCode == 200) {
          final responseData = jsonDecode(responseBody);
          imageUrls.add(responseData['url']);
        } else {
          throw Exception('Failed to upload image: ${response.statusCode} - $responseBody');
        }
      } catch (e) {
        debugPrint('Error uploading image: $e');
        rethrow;
      }
    }
    return imageUrls;
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
      debugPrint('Starting report submission...');
      List<String> imageUrls = [];
      
      if (_selectedImages.isNotEmpty) {
        debugPrint('Uploading ${_selectedImages.length} images...');
        imageUrls = await _uploadImages();
        debugPrint('Images uploaded successfully: $imageUrls');
      }

      // Added debugging log to verify `_priority` value
      debugPrint('Selected priority: ${_priority.name}');

      debugPrint('Creating incident object...');
      final incident = Incident(
        id: '',  // Will be set by MongoDB
        title: _titleController.text,
        description: _descriptionController.text,
        location: {
          'type': 'Point',
          'coordinates': [
            _selectedLocation!.longitude, // MongoDB uses [longitude, latitude]
            _selectedLocation!.latitude,
          ],
        },
        address: _addressController.text.isEmpty 
            ? 'Location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}'
            : _addressController.text,
        category: _category,
        priority: _priority,
        status: IncidentStatus.open,
        reporterId: Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 'anonymous',
        images: imageUrls,
        createdAt: DateTime.now(),
        resolvedAt: null,
      );

      debugPrint('Saving incident to MongoDB...');
      final service = Provider.of<IncidentService>(context, listen: false);
      await service.createIncident(incident);
      debugPrint('Incident saved successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident reported successfully')),
        );
        Navigator.pop(context, true); // Pass `true` to indicate a new report was added
      }
    } catch (e, stackTrace) {
      debugPrint('Error submitting report: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmAndSubmitReport() async {
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Report'),
        content: const Text('Are you sure you want to submit this incident report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (shouldSubmit == true) {
      _submitReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isLoading
            ? Center(
                key: const ValueKey('loading'),
                child: AnimatedOpacity(
                  opacity: _isLoading ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: const CircularProgressIndicator(),
                ),
              )
            : SingleChildScrollView(
                key: const ValueKey('form'),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: AnimatedOpacity(
                  opacity: _showForm ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Incident Details', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Title',
                                    border: OutlineInputBorder(),
                                    helperText: 'Brief description of the incident',
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
                                    helperText: 'Detailed description of what happened',
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _category,
                                        decoration: const InputDecoration(
                                          labelText: 'Category',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: _categories
                                            .map((category) => DropdownMenuItem(
                                                  value: category,
                                                  child: Text(category),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _category = value!;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButtonFormField<IncidentPriority>(
                                        value: _priority,
                                        decoration: const InputDecoration(
                                          labelText: 'Priority',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: IncidentPriority.values
                                            .map((priority) => DropdownMenuItem(
                                                  value: priority,
                                                  child: Text(priority.name.toUpperCase()),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _priority = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: const InputDecoration(
                                    labelText: 'Address (optional)',
                                    border: OutlineInputBorder(),
                                    helperText: 'Specific location details (optional)',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Location', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 3,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 200,
                                child: FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    center: _selectedLocation ?? LatLng(0, 0),
                                    zoom: 15,
                                    onTap: (tapPosition, point) {
                                      setState(() {
                                        _selectedLocation = point;
                                      });
                                    },
                                  ),
                                  nonRotatedChildren: [
                                    if (_selectedLocation != null)
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: _selectedLocation!,
                                            width: 40,
                                            height: 40,
                                            child: const Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.safety.community_dashboard',
                                      tileProvider: CancellableNetworkTileProvider(),
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
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.my_location),
                                      tooltip: 'Use your current location',
                                      onPressed: _getCurrentLocation,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Images', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Tooltip(
                                      message: 'Pick images from your gallery',
                                      child: ElevatedButton.icon(
                                        onPressed: _pickImages,
                                        icon: const Icon(Icons.photo_library),
                                        label: const Text('Gallery'),
                                        style: ElevatedButton.styleFrom(elevation: 2),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Tooltip(
                                      message: 'Capture a new photo',
                                      child: ElevatedButton.icon(
                                        onPressed: _captureImage,
                                        icon: const Icon(Icons.camera_alt),
                                        label: const Text('Camera'),
                                        style: ElevatedButton.styleFrom(elevation: 2),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: _selectedImages.isNotEmpty
                                      ? SizedBox(
                                          height: 100,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: _selectedImages.length,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Stack(
                                                  children: [
                                                    Material(
                                                      elevation: 2,
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: kIsWeb
                                                            ? Image.network(
                                                                _selectedImages[index].path,
                                                                fit: BoxFit.cover,
                                                                width: 100,
                                                                height: 100,
                                                              )
                                                            : Image.file(
                                                                File(_selectedImages[index].path),
                                                                fit: BoxFit.cover,
                                                                width: 100,
                                                                height: 100,
                                                              ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 0,
                                                      right: 0,
                                                      child: InkWell(
                                                        onTap: () => _removeImage(index),
                                                        borderRadius: BorderRadius.circular(16),
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            color: Colors.black54,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Divider(height: 1, color: theme.dividerColor),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _confirmAndSubmitReport,
                            icon: const Icon(Icons.send),
                            label: const Text('Submit Report'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}