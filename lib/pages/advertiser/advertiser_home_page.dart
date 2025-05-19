import 'package:flutter/material.dart';
import 'dart:io';
import 'package:governmentapp/models/advertisement.dart';
import 'package:governmentapp/services/advertisement/adv_service.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/services/google_drive/google_drive_service.dart';
import 'package:governmentapp/utils/logger.dart';
import 'package:governmentapp/widgets/my_advertisement_tile.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:governmentapp/widgets/my_small_button.dart';
import 'package:governmentapp/widgets/my_steps_card.dart';
import 'package:governmentapp/widgets/my_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AdvertiserHomePage extends StatefulWidget {
  const AdvertiserHomePage({super.key});

  @override
  State<AdvertiserHomePage> createState() => _AdvertiserHomePageState();
}

class _AdvertiserHomePageState extends State<AdvertiserHomePage> {
  int currentIndex = 0;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  final AdvService _advService = AdvService();
  final AuthService _authService = AuthService();
  final GoogleDriveService _driveService = GoogleDriveService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isUploading = false;

  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacementNamed(context, "/advertiser_home");
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          // Clear any existing URL since we're using a local file now
          imageController.clear();
        });
      }
    } catch (e) {
      AppLogger.e("Error picking image", e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting image: $e")),
      );
    }
  }

  Future<String?> _uploadImageToDrive() async {
    if (_selectedImage == null) {
      return null;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Initialize Drive service
      await _driveService.initialize();
      
      final fileName = 'advertisement_${DateTime.now().millisecondsSinceEpoch}';
      final url = await _driveService.uploadImageToDrive(_selectedImage!, fileName);
      
      // Verify the uploaded file is accessible
      final response = await http.head(Uri.parse(url));
      if (response.statusCode != 200) {
        AppLogger.w('Uploaded file might not be immediately accessible: $url');
        // Add a short delay to allow Google Drive to process the file
        await Future.delayed(const Duration(seconds: 1));
      }
      
      AppLogger.i('Successfully uploaded advertisement image: $fileName, URL: $url');
      return url;
    } catch (e) {
      AppLogger.e('Error uploading image', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void onTapCreateAdvertisement(BuildContext context) {
    final theme = Theme.of(context);
    
    // Reset state for new advertisement
    _selectedImage = null;
    titleController.clear();
    descriptionController.clear();
    imageController.clear();
    categoryController.clear();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and icon
                Row(
                  children: [
                    Icon(
                      Icons.campaign_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Create Advertisement",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Fill in the details to create your new advertisement",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const Divider(height: 24),
                
                // Form fields
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title field
                        Text(
                          "Title",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        MyTextfield(
                          hintText: "Enter a catchy title",
                          obSecure: false,
                          controller: titleController,
                          prefixIcon: Icon(Icons.title, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        
                        // Description field
                        Text(
                          "Description",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        MyTextfield(
                          hintText: "Describe your advertisement",
                          obSecure: false,
                          controller: descriptionController,
                          prefixIcon: Icon(Icons.description, color: theme.colorScheme.primary),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        
                        // Image Upload section
                        Text(
                          "Advertisement Image",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Image selection options
                        Row(
                          children: [
                            // Option 1: Upload from device
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  await _pickImage();
                                  setState(() {}); // Update the UI to show selected image
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: theme.colorScheme.primary.withAlpha((0.5 * 255).toInt())),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.photo_library,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Upload Image",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Option 2: Enter URL
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    "OR",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  MyTextfield(
                                    hintText: "Enter image URL",
                                    obSecure: false,
                                    controller: imageController,
                                    prefixIcon: Icon(Icons.link, color: theme.colorScheme.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Category field
                        Text(
                          "Category",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        MyTextfield(
                          hintText: "Select a category",
                          obSecure: false,
                          controller: categoryController,
                          prefixIcon: Icon(Icons.category, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        
                        // Preview section
                        if (_selectedImage != null || imageController.text.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Preview",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : imageController.text.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          imageController.text,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.grey[400],
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.image,
                                          color: Colors.grey[400],
                                          size: 40,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isUploading 
                        ? null 
                        : () async {
                          // Validate inputs
                          if (titleController.text.isEmpty || 
                              descriptionController.text.isEmpty || 
                              categoryController.text.isEmpty ||
                              (_selectedImage == null && imageController.text.isEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill all fields and provide an image")),
                            );
                            return;
                          }
                          
                          String imageUrl = imageController.text;
                          
                          // If we have a selected image, upload it
                          if (_selectedImage != null) {
                            setState(() {
                              _isUploading = true;
                            });
                            
                            final uploadedUrl = await _uploadImageToDrive();
                            if (uploadedUrl == null) {
                              setState(() {
                                _isUploading = false;
                              });
                              return; // Error already shown in _uploadImageToDrive
                            }
                            
                            imageUrl = uploadedUrl;
                          }
                          
                          final advertisement = Advertisement(
                            id: '', // Will be set by the service
                            advertiserId: _authService.getCurrentUser()!.uid,
                            title: titleController.text,
                            description: descriptionController.text,
                            imageUrl: imageUrl,
                            category: categoryController.text,
                          );
                          
                          // Create the advertisement
                          await _advService.createAdvertisement(advertisement);
                          
                          // Clear form and close dialog
                          titleController.clear();
                          descriptionController.clear();
                          imageController.clear();
                          categoryController.clear();
                          _selectedImage = null;
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Advertisement submitted for approval")),
                            );
                          }
                        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isUploading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text("Create"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onTapEditAdvertisement(
    BuildContext context,
    Advertisement advertisement,
  ) {
    final theme = Theme.of(context);
    
    // Pre-fill the controllers with existing values
    titleController.text = advertisement.title;
    descriptionController.text = advertisement.description;
    imageController.text = advertisement.imageUrl;
    categoryController.text = advertisement.category;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and icon
              Row(
                children: [
                  Icon(
                    Icons.edit_document,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Edit Advertisement",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Update your advertisement details",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Divider(height: 24),
              
              // Form fields
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      Text(
                        "Title",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MyTextfield(
                        hintText: "Enter a catchy title",
                        obSecure: false,
                        controller: titleController,
                        prefixIcon: Icon(Icons.title, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      
                      // Description field
                      Text(
                        "Description",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MyTextfield(
                        hintText: "Describe your advertisement",
                        obSecure: false,
                        controller: descriptionController,
                        prefixIcon: Icon(Icons.description, color: theme.colorScheme.primary),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Image URL field
                      Text(
                        "Image URL",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MyTextfield(
                        hintText: "Enter image URL",
                        obSecure: false,
                        controller: imageController,
                        prefixIcon: Icon(Icons.image, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      
                      // Category field
                      Text(
                        "Category",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MyTextfield(
                        hintText: "Select a category",
                        obSecure: false,
                        controller: categoryController,
                        prefixIcon: Icon(Icons.category, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      
                      // Preview section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Preview",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imageController.text,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey[400],
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Status: ${advertisement.status.toUpperCase()}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: advertisement.status == 'approved' 
                                        ? Colors.green[700] 
                                        : advertisement.status == 'rejected'
                                            ? Colors.red[700]
                                            : Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      // Only update fields that have changed
                      await _advService.updateAdvertisementFields(
                        advertisement.id,
                        title:
                            titleController.text != advertisement.title
                                ? titleController.text
                                : null,
                        description:
                            descriptionController.text != advertisement.description
                                ? descriptionController.text
                                : null,
                        imageUrl:
                            imageController.text != advertisement.imageUrl
                                ? imageController.text
                                : null,
                        category:
                            categoryController.text != advertisement.category
                                ? categoryController.text
                                : null,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Update"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onTapDeleteAdvertisement(
    BuildContext context,
    Advertisement advertisement,
  ) {
    _advService.deleteAdvertisement(advertisement.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome ${_authService.getCurrentUser()!.email}"),
      ),
      drawer: MyDrawer(role: 'advertiser'),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "My Advertisements",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                SizedBox(width: 10),
                MySmallButton(
                  text: "Create New Ad",
                  onTap: () => onTapCreateAdvertisement(context),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder(
                stream: _advService.getAdvertisementsForUser(
                  _authService.getCurrentUser()!.uid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No advertisements found"));
                  }

                  final advertisements = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: advertisements.length,
                    itemBuilder: (context, index) {
                      final adData =
                          advertisements[index].data() as Map<String, dynamic>;
                      final advertisement = Advertisement.fromMap({
                        'id': advertisements[index].id,
                        ...adData,
                      });
                      return MyAdvertisementTile(
                        advertisement: advertisement,
                        onPressedEdit:
                            () =>
                                onTapEditAdvertisement(context, advertisement),
                        onPressedDelete:
                            () => onTapDeleteAdvertisement(
                              context,
                              advertisement,
                            ),
                      );
                    },
                  );
                },
              ),
            ),
            MyStepsCard(
              steps: [
                "Ad must be relevant to the local community",
                "Content must be appropriate and not offensive",
                "Images should be high quality and clearly show the subject",
                "All submitted ads will be reviewed by the government",
              ],
            ),
          ],
        ),
      ),
    );
  }
}
