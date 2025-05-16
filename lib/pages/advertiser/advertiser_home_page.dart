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
                    id: '', // Will be set by the service
                    advertiserId: _authService.getCurrentUser()!.uid,
                    title: titleController.text,
                    description: descriptionController.text,
                    imageUrl: imageController.text,
                    category: categoryController.text,
                  );
                  // print(advertisement);
                  // print(advertisement.toMap());
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

  void onTapEditAdvertisement(
    BuildContext context,
    Advertisement advertisement,
  ) {
    // Pre-fill the controllers with existing values
    titleController.text = advertisement.title;
    descriptionController.text = advertisement.description;
    imageController.text = advertisement.imageUrl;
    categoryController.text = advertisement.category;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Edit Advertisement"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
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
                  hintText: "Advertisement Image URL",
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
                child: Text("Update"),
              ),
            ],
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
