import 'package:flutter/material.dart';
import 'package:governmentapp/models/advertisement.dart';
import 'package:governmentapp/services/advertisement/adv_service.dart';
import 'package:governmentapp/widgets/government_advertisement_tile.dart';

class GovernmentAdvertisementsManagement extends StatefulWidget {
  const GovernmentAdvertisementsManagement({super.key});

  @override
  State<GovernmentAdvertisementsManagement> createState() =>
      _GovernmentAdvertisementsManagementState();
}

class _GovernmentAdvertisementsManagementState
    extends State<GovernmentAdvertisementsManagement> {
  final AdvService _advService = AdvService();
  bool showPending = true;

  Future<void> _showEditDialog(Advertisement advertisement) async {
    final TextEditingController titleController = TextEditingController(text: advertisement.title);
    final TextEditingController descriptionController = TextEditingController(text: advertisement.description);
    final TextEditingController imageController = TextEditingController(text: advertisement.imageUrl);
    final TextEditingController categoryController = TextEditingController(text: advertisement.category);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Advertisement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _advService.updateAdvertisementFields(
                advertisement.id,
                title: titleController.text != advertisement.title ? titleController.text : null,
                description: descriptionController.text != advertisement.description ? descriptionController.text : null,
                imageUrl: imageController.text != advertisement.imageUrl ? imageController.text : null,
                category: categoryController.text != advertisement.category ? categoryController.text : null,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertisements Management'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/government_home');
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ],
      ),
      body: Column(
        children: [
          // Buttons for switching between pending and approved
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showPending = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            showPending
                                ? Theme.of(context).colorScheme.primary
                                : null,
                        foregroundColor: showPending ? Colors.white : null,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Pending', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showPending = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            !showPending
                                ? Theme.of(context).colorScheme.primary
                                : null,
                        foregroundColor: !showPending ? Colors.white : null,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Approved', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream:
                  showPending
                      ? _advService.getPendingAdvertisements()
                      : _advService.getApprovedAdvertisements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No advertisements found',
                    ),
                  );
                }
                final advertisements = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: advertisements.length,
                  itemBuilder: (context, index) {
                    final adData = advertisements[index];
                    final advertisement = Advertisement(
                      id: adData.id,
                      advertiserId: adData['advertiserId'],
                      title: adData['title'],
                      description: adData['description'],
                      imageUrl: adData['imageUrl'],
                      category: adData['category'],
                      status: adData['status'],
                    );
                    return GovernmentAdvertisementTile(
                      status: advertisement.status,
                      advertisement: advertisement,
                      onPressedApprove:
                          showPending
                              ? () async {
                                await _advService.approveAdvertisement(
                                  advertisement.id,
                                );
                              }
                              : null,
                      onPressedReject:
                          showPending
                              ? () async {
                                await _advService.rejectAdvertisement(
                                  advertisement.id,
                                );
                                await _advService.deleteAdvertisement(
                                  advertisement.id,
                                );
                              }
                              : null,
                      onPressedEdit: () => _showEditDialog(advertisement),
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
