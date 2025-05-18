import 'package:flutter/material.dart';
import 'package:governmentapp/models/advertisement.dart';
import 'package:governmentapp/services/advertisement/adv_service.dart';
import 'package:governmentapp/widgets/my_advertisement_tile.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart';

class CitizenAdvertisementPage extends StatelessWidget {
  const CitizenAdvertisementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AdvService _advertisementService = AdvService();

    return RouteGuardWrapper(
      allowedRoles: const ['citizen'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Advertisements'),
          centerTitle: true,
        ),
        drawer: MyDrawer(role: 'citizen'),
        body: StreamBuilder(
          stream: _advertisementService.getApprovedAdvertisements(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final advertisements = snapshot.data?.docs
                .map((doc) => Advertisement.fromMap(doc.data() as Map<String, dynamic>))
                .toList() ?? [];

            if (advertisements.isEmpty) {
              return const Center(
                child: Text('No advertisements available'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: advertisements.length,
              itemBuilder: (context, index) {
                final advertisement = advertisements[index];
                return MyAdvertisementTile(
                  advertisement: advertisement,
                  onPressedEdit: null,
                  onPressedDelete: null,
                  showActions: false,
                );
              },
            );
          },
        ),
        bottomNavigationBar: MyBottomNavigationBar(
          currentIndex: 4, // Messages tab
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/citizen_home');
            } else if (index == 1) {
              Navigator.pushReplacementNamed(context, '/citizen_announcements');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/citizen_polls');
            } else if (index == 3) {
              Navigator.pushReplacementNamed(context, '/citizen_report');
            } else if (index == 4) {
              // Already on Messages page
            }
          },
        ),
      ),
    );
  }
}
