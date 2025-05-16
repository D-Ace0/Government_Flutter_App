import 'package:flutter/material.dart';
import 'package:governmentapp/widgets/my_advertisements_list.dart';
import 'package:governmentapp/widgets/my_drawer.dart';

class AdvertiserHomePage extends StatelessWidget {
  const AdvertiserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Advertiser")),
      drawer: MyDrawer(),
      body: Column(children: [MyAdvertisementsList()]),
    );
  }
}
