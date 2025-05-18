import 'package:flutter/material.dart';
import 'package:governmentapp/models/official_phone.dart';
import 'package:governmentapp/services/official_phone/phone_service.dart';
import 'package:governmentapp/widgets/official_phone_card.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';

class CitizenPhoneDirectory extends StatelessWidget {
  const CitizenPhoneDirectory({super.key});

  @override
  Widget build(BuildContext context) {
    final PhoneService _phoneService = PhoneService();

    return RouteGuardWrapper(
      allowedRoles: const ['citizen'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Official Phone Directory'),
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Important Phone Numbers",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                      child: Text("No phone numbers available"),
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
