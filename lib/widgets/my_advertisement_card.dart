import 'package:flutter/material.dart';
import 'package:governmentapp/models/advertisement.dart';

class MyAdvertisementCard extends StatelessWidget {
  final Advertisement advertisement;
  const MyAdvertisementCard({super.key, required this.advertisement});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                Text(
                  advertisement.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                // status
                Text(advertisement.isApproved ? "Approved" : "Pending"),
              ],
            ),
            // advertisement description
            Text(advertisement.description),

            // advertisement image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                advertisement.imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) =>
                        Icon(Icons.broken_image, size: 100),
              ),
            ),
            // edit button
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(onPressed: () {}, icon: Icon(Icons.edit)),
            ),
          ],
        ),
      ),
    );
  }
}
