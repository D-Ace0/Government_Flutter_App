import 'package:flutter/material.dart';
import 'package:governmentapp/models/advertisement.dart';

class GovernmentAdvertisementCard extends StatelessWidget {
  final Advertisement advertisement;
  final String status;
  final void Function()? onPressedApprove;
  final void Function()? onPressedReject;
  final void Function()? onPressedEdit;
  const GovernmentAdvertisementCard({
    super.key,
    required this.advertisement,
    required this.status,
    this.onPressedApprove,
    this.onPressedReject,
    this.onPressedEdit,
  }) : assert(
         status != 'pending' ||
             (onPressedApprove != null && onPressedReject != null),
         'onPressedApprove and onPressedReject must be provided when status is pending',
       );

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
                    child: Text(advertisement.status.toString().toUpperCase()),
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
            // Action buttons
            if (status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: onPressedApprove,
                    icon: const Icon(Icons.check, color: Colors.green),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    onPressed: onPressedEdit,
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: onPressedReject,
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Reject',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
