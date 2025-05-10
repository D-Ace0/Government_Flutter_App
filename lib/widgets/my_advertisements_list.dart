import 'package:flutter/material.dart';
import 'package:governmentapp/widgets/my_advertisement_tile.dart';

class MyAdvertisementsList extends StatelessWidget {
  const MyAdvertisementsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return Card(child: MyAdvertisementTile());
      },
    );
  }
}
