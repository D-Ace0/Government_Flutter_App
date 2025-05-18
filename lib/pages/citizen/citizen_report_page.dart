import 'dart:io';
import 'package:flutter/material.dart';
import 'package:governmentapp/models/reports.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/services/report/report_service.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:governmentapp/widgets/my_text_field.dart';
import 'package:governmentapp/widgets/my_small_button.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';

class CitizenReportPage extends StatefulWidget {
  const CitizenReportPage({super.key});

  @override
  State<CitizenReportPage> createState() => _CitizenReportPageState();
}

class _CitizenReportPageState extends State<CitizenReportPage> {
  int currentIndex = 3; // Set to 3 for "Report" tab in bottom navigation
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final ReportService _reportService = ReportService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<File> selectedImages = [];
  LatLng? selectedLocation;
  bool isLoading = false;
  MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Set a default location (can be updated later)
    selectedLocation = LatLng(0, 0);
  }

  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/citizen_home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/citizen_announcements');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/citizen_polls');
    } else if (index == 3) {
      // Already on report page - no navigation needed
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/citizen_messages');
    }
  }

  Future<void> _pickImages() async {
    try {
      List<XFile> pickedImages = await _imagePicker.pickMultiImage();
      if (pickedImages.isNotEmpty) {
        setState(() {
          selectedImages.addAll(pickedImages.map((image) => File(image.path)));
        });
        
        print('Selected ${pickedImages.length} images');
      }
    } catch (e) {
      print("Error picking images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      XFile? photo = await _imagePicker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          selectedImages.add(File(photo.path));
        });
        
        print('Took a photo: ${photo.path}');
      }
    } catch (e) {
      print("Error taking photo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take photo')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
    
    print('Removed image at index $index, ${selectedImages.length} remaining');
  }

  Future<void> _submitReport() async {
    if (titleController.text.isEmpty || 
        descriptionController.text.isEmpty ||
        locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      print('Submitting report with ${selectedImages.length} images');
      
      // Verify the images exist
      for (int i = 0; i < selectedImages.length; i++) {
        if (!selectedImages[i].existsSync()) {
          print('Warning: Image file ${selectedImages[i].path} does not exist');
        } else {
          print('Image ${i+1}: ${selectedImages[i].path} (${selectedImages[i].lengthSync()} bytes)');
        }
      }

      final report = Report(
        id: '', // Will be set by the service
        title: titleController.text,
        description: descriptionController.text,
        status: 'pending',
        location: locationController.text,
        reporterId: _authService.getCurrentUser()!.uid,
        imageUrls: [],
        latitude: selectedLocation!.latitude,
        longitude: selectedLocation!.longitude,
      );

      final reportId = await _reportService.createReport(report, selectedImages);
      print('Report created with ID: $reportId');

      setState(() {
        isLoading = false;
        titleController.clear();
        descriptionController.clear();
        locationController.clear();
        selectedImages.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report submitted successfully'),
          action: SnackBarAction(
            label: 'View Reports',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/citizen_report_history');
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error submitting report: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(role: 'citizen'),
      appBar: AppBar(
        title: Text(
          "Report an Issue",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'View Report History',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/citizen_report_history');
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Submit a Problem Report",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Report Form
                    MyTextfield(
                      hintText: "Issue Title (e.g., Broken Streetlight)",
                      obSecure: false,
                      controller: titleController,
                    ),
                    SizedBox(height: 8),
                    
                    MyTextfield(
                      hintText: "Description of the Issue",
                      obSecure: false,
                      controller: descriptionController,
                      maxLines: 3,
                    ),
                    SizedBox(height: 8),
                    
                    MyTextfield(
                      hintText: "Location Description (e.g., Main St & 5th Ave)",
                      obSecure: false,
                      controller: locationController,
                    ),
                    SizedBox(height: 16),
                    
                    // Map for location selection
                    Text(
                      "Mark Issue Location on Map",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: selectedLocation ?? LatLng(0, 0),
                            initialZoom: 15.0,
                            onTap: (tapPosition, point) {
                              setState(() {
                                selectedLocation = point;
                                print('Selected location: $point');
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.governmentapp',
                            ),
                            if (selectedLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: selectedLocation!,
                                    child: Icon(
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
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        "Tap anywhere on the map to select location",
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Image upload section
                    Text(
                      "Add Photos (${selectedImages.length})",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: Icon(Icons.photo_library),
                          label: Text("Gallery"),
                        ),
                        OutlinedButton.icon(
                          onPressed: _takePhoto,
                          icon: Icon(Icons.camera_alt),
                          label: Text("Camera"),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Display selected images
                    if (selectedImages.isNotEmpty) ...[
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(right: 8),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(selectedImages[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 10,
                                  top: 5,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                    
                    // Submit button
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitReport,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: Text(
                          "Submit Report",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
  }
} 