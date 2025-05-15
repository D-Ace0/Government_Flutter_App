import 'package:flutter/material.dart';
import 'package:governmentapp/models/advertisement.dart';
import 'package:governmentapp/services/advertisement/adv_service.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/widgets/my_advertisement_tile.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:governmentapp/widgets/my_small_button.dart';
import 'package:governmentapp/widgets/my_steps_card.dart';
import 'package:governmentapp/widgets/my_text_field.dart';

class AdvertiserHomePage extends StatefulWidget {
  AdvertiserHomePage({super.key});

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

  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacementNamed(context, "/advertiser_home");
    }
  }

  void onTapCreateAdvertisement(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Create Advertisement"),
            content: Column(
              children: [
                MyTextfield(
                  hintText: "Advertisement Title",
                  obSecure: false,
                  controller: titleController,
                ),
                MyTextfield(
                  hintText: "Advertisement Description",
                  obSecure: false,
                  controller: descriptionController,
                ),
                MyTextfield(
                  hintText: "Advertisement Image",
                  obSecure: false,
                  controller: imageController,
                ),
                MyTextfield(
                  hintText: "Advertisement Category",
                  obSecure: false,
                  controller: categoryController,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  final advertisement = Advertisement(
                    advertiserId: _authService.getCurrentUser()!.uid,
                    title: titleController.text,
                    description: descriptionController.text,
                    imageUrl: imageController.text,
                    category: categoryController.text,
                  );
                  print(advertisement);
                  print(advertisement.toMap());
                  _advService.createAdvertisement(advertisement);
                  Navigator.pop(context);
                  titleController.clear();
                  descriptionController.clear();
                  imageController.clear();
                  categoryController.clear();
                },
                child: Text("Create"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Advertiser")),
      drawer: MyDrawer(),
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
                      final adData = advertisements[index];
                      final advertisement = Advertisement(
                        advertiserId: adData['advertiserId'],
                        title: adData['title'],
                        description: adData['description'],
                        imageUrl: adData['imageUrl'],
                        category: adData['category'],
                      );
                      return MyAdvertisementTile(advertisement: advertisement);
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
