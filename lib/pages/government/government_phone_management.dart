import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:governmentapp/models/official_phone.dart';
import 'package:governmentapp/services/official_phone/phone_service.dart';
import 'package:governmentapp/widgets/my_text_field.dart';
import 'package:governmentapp/widgets/official_phone_card.dart';

class GovernmentPhoneManagement extends StatefulWidget {
  const GovernmentPhoneManagement({super.key});

  @override
  State<GovernmentPhoneManagement> createState() =>
      _GovernmentPhoneManagementState();
}

class _GovernmentPhoneManagementState extends State<GovernmentPhoneManagement> {
  final PhoneService _phoneService = PhoneService();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  void _showAddPhoneDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add Official Phone Number"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyTextfield(
                  hintText: "Department Name",
                  controller: departmentController,
                  obSecure: false,
                ),
                const SizedBox(height: 8),
                MyTextfield(
                  hintText: "Phone Number",
                  controller: phoneNumberController,
                  obSecure: false,
                ),
                const SizedBox(height: 8),
                MyTextfield(
                  hintText: "Description",
                  controller: descriptionController,
                  obSecure: false,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  departmentController.clear();
                  phoneNumberController.clear();
                  descriptionController.clear();
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (departmentController.text.isNotEmpty &&
                      phoneNumberController.text.isNotEmpty &&
                      descriptionController.text.isNotEmpty) {
                    final phone = OfficialPhone(
                      id: '',
                      department: departmentController.text,
                      phoneNumber: phoneNumberController.text,
                      description: descriptionController.text,
                      timestamp: Timestamp.now(),
                    );
                    await _phoneService.addOfficialPhone(phone);
                    if (context.mounted) {
                      Navigator.pop(context);
                      departmentController.clear();
                      phoneNumberController.clear();
                      descriptionController.clear();
                    }
                  }
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  void _showEditPhoneDialog(OfficialPhone phone) {
    // Pre-fill the text controllers with the existing data
    departmentController.text = phone.department;
    phoneNumberController.text = phone.phoneNumber;
    descriptionController.text = phone.description;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Official Phone Number"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyTextfield(
              hintText: "Department Name",
              controller: departmentController,
              obSecure: false,
            ),
            const SizedBox(height: 8),
            MyTextfield(
              hintText: "Phone Number",
              controller: phoneNumberController,
              obSecure: false,
            ),
            const SizedBox(height: 8),
            MyTextfield(
              hintText: "Description",
              controller: descriptionController,
              obSecure: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              departmentController.clear();
              phoneNumberController.clear();
              descriptionController.clear();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (departmentController.text.isNotEmpty &&
                  phoneNumberController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty) {
                // Update the phone with new values
                final updatedPhone = OfficialPhone(
                  id: phone.id,
                  department: departmentController.text,
                  phoneNumber: phoneNumberController.text,
                  description: descriptionController.text,
                  timestamp: phone.timestamp,
                );
                await _phoneService.updateOfficialPhone(updatedPhone);
                if (context.mounted) {
                  Navigator.pop(context);
                  departmentController.clear();
                  phoneNumberController.clear();
                  descriptionController.clear();
                }
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phone Numbers Management"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Official Phone Numbers",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    overflow: TextOverflow.clip,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddPhoneDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Add New"),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _phoneService.getOfficialPhones(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No phone numbers added yet"),
                  );
                }

                final phones = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: phones.length,
                  itemBuilder: (context, index) {
                    final phoneData = phones[index];
                    final phone = OfficialPhone(
                      id: phoneData.id,
                      department: phoneData['department'],
                      phoneNumber: phoneData['phoneNumber'],
                      description: phoneData['description'],
                      timestamp: phoneData['timestamp'],
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: OfficialPhoneCard(
                        phone: phone,
                        onPressedEdit: () {
                          _showEditPhoneDialog(phone);
                        },
                        onPressedDelete: () async {
                          await _phoneService.deleteOfficialPhone(phone.id);
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
    );
  }
}
