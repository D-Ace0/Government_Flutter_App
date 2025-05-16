import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:governmentapp/services/announcement/announcement_service.dart';
import 'package:governmentapp/widgets/my_button.dart';
import 'package:governmentapp/widgets/my_text_field.dart';

class PostAnnouncementPage extends StatefulWidget {
  const PostAnnouncementPage({super.key});

  @override
  State<PostAnnouncementPage> createState() => _PostAnnouncementPageState();
}

class _PostAnnouncementPageState extends State<PostAnnouncementPage> {
  final _titleController = TextEditingController(); // controller for title field
  final _descController = TextEditingController();  // controller for description field
  final _categoryController = TextEditingController(); // controller for category field
  final AnnouncementService _service = AnnouncementService(); // instance of announcement service

  File? _attachment; // file for optional image/pdf attachment

  Future<void> _pickFile() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery); // pick image from gallery
    if (pickedFile != null) {
      setState(() => _attachment = File(pickedFile.path)); // update state if file is picked
    }
  }

  Future<void> _submit() async {
    try {
      // Validate required fields
      if (_titleController.text.isEmpty || _descController.text.isEmpty) {
        throw Exception("Title and description are required");
      }

      // Call service to post announcement
      await _service.postAnnouncement(
        title: _titleController.text,
        description: _descController.text,
        category: _categoryController.text,
        attachment: _attachment,
      );

      // Show success and go back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Announcement has been posted.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Announcement")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              MyTextfield(
                controller: _titleController,
                hintText: "Title *",
                obSecure: false,
              ),
              const SizedBox(height: 12),
              MyTextfield(
                controller: _descController,
                hintText: "Description *",
                obSecure: false,
              ),
              const SizedBox(height: 12),
              MyTextfield(
                controller: _categoryController,
                hintText: "Category (optional)",
                obSecure: false,
              ),
              const SizedBox(height: 12),
              if (_attachment != null)
                Column(
                  children: [
                    Image.file(_attachment!, height: 150),
                    TextButton(
                      onPressed: () => setState(() => _attachment = null),
                      child: const Text("Remove attachment"),
                    ),
                  ],
                ),
              MyButton(text: "Post", onTap: _submit),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text("Add Attachment"),
                onPressed: _pickFile,
              )
            ],
          ),
        ),
      ),
    );
  }
}