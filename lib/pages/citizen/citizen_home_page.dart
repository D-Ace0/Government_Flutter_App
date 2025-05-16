import 'package:flutter/material.dart';
import 'package:governmentapp/models/advertisement.dart';
import 'package:governmentapp/models/official_phone.dart';
import 'package:governmentapp/services/advertisement/adv_service.dart';
import 'package:governmentapp/services/official_phone/phone_service.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:governmentapp/widgets/government_advertisement_card.dart';
import 'package:governmentapp/widgets/official_phone_card.dart';

class CitizenHomePage extends StatefulWidget {
  const CitizenHomePage({super.key});

  @override
  State<CitizenHomePage> createState() => _CitizenHomePageState();
}

class _CitizenHomePageState extends State<CitizenHomePage> {
  int _selectedIndex = 0;
  final AdvService _advService = AdvService();
  final PhoneService _phoneService = PhoneService();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the appropriate page when a tab is clicked
    if (index == 3) {
      // Messages tab
      Navigator.pushReplacementNamed(context, '/citizen_message');
    }
  }

  void _showOfficialPhones() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Official Phone Numbers",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: StreamBuilder(
                      stream: _phoneService.getOfficialPhones(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text("No official phone numbers available"),
                          );
                        }

                        final phones = snapshot.data!.docs;
                        return ListView.builder(
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
                              child: OfficialPhoneCard(phone: phone),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Citizen"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showOfficialPhones,
            icon: const Icon(Icons.phone),
          ),
        ],
      ),
      drawer: MyDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Approved Advertisements",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _advService.getApprovedAdvertisements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No approved advertisements available",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final advertisements = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
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

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GovernmentAdvertisementCard(
                        advertisement: advertisement,
                        status: advertisement.status!,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
