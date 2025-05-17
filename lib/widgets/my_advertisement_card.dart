import 'package:flutter/material.dart';
import 'package:governmentapp/models/advertisement.dart';

class MyAdvertisementCard extends StatelessWidget {
  final Advertisement advertisement;
  final void Function()? onPressedEdit;
  final void Function()? onPressedDelete;
  const MyAdvertisementCard({
    super.key,
    required this.advertisement,
    required this.onPressedEdit,
    required this.onPressedDelete,
  });

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
                Container(
                  decoration: BoxDecoration(
                    color:
                        advertisement.status == 'approved'
                            ? Colors.green
                            : advertisement.status == 'rejected'
                            ? Colors.red
                            : Colors.yellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4,
                    ),
                    child: Text(
                      advertisement.status.toUpperCase() ?? 'PENDING',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // advertisement description
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                advertisement.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: onPressedEdit, icon: Icon(Icons.edit)),
                IconButton(
                  onPressed: onPressedDelete,
                  icon: Icon(Icons.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
