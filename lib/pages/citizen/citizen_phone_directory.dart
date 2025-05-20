import 'package:flutter/material.dart';
import 'package:governmentapp/models/official_phone.dart';
import 'package:governmentapp/services/official_phone/phone_service.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class CitizenPhoneDirectory extends StatefulWidget {
  const CitizenPhoneDirectory({super.key});

  @override
  State<CitizenPhoneDirectory> createState() => _CitizenPhoneDirectoryState();
}

class _CitizenPhoneDirectoryState extends State<CitizenPhoneDirectory> {
  final PhoneService _phoneService = PhoneService();
  String _searchQuery = '';

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RouteGuardWrapper(
      allowedRoles: const ['citizen'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Official Phone Directory'),
          centerTitle: true,
        ),
        drawer: const MyDrawer(role: 'citizen'),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search departments...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            // Phone list
            Expanded(
              child: StreamBuilder(
                stream: _phoneService.getOfficialPhones(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_missed,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No phone numbers available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final phones = snapshot.data!.docs;
                  
                  // Filter the phones based on search query
                  final filteredPhones = phones.where((phoneDoc) {
                    final department = phoneDoc['department'].toString().toLowerCase();
                    final description = phoneDoc['description'].toString().toLowerCase();
                    
                    return department.contains(_searchQuery) || 
                           description.contains(_searchQuery);
                  }).toList();
                  
                  if (filteredPhones.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No matching departments found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredPhones.length,
                    itemBuilder: (context, index) {
                      final phoneData = filteredPhones[index];
                      final phone = OfficialPhone(
                        id: phoneData.id,
                        department: phoneData['department'],
                        phoneNumber: phoneData['phoneNumber'],
                        description: phoneData['description'],
                        timestamp: phoneData['timestamp'],
                      );
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _makePhoneCall(phone.phoneNumber),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        phone.department,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _makePhoneCall(phone.phoneNumber),
                                      icon: Icon(
                                        Icons.call,
                                        color: theme.colorScheme.primary,
                                      ),
                                      tooltip: 'Call',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  phone.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        phone.phoneNumber,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 