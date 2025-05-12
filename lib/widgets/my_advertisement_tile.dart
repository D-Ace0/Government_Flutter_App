import 'package:flutter/material.dart';
import 'package:governmentapp/models/advertisement.dart';
import 'package:governmentapp/widgets/my_advertisement_card.dart';

class MyAdvertisementTile extends StatelessWidget {
  final Advertisement advertisement;
  const MyAdvertisementTile({super.key, required this.advertisement});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MyAdvertisementCard(advertisement: advertisement),
    );
  }
}
