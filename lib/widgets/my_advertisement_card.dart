import 'package:flutter/material.dart';
import 'package:governmentapp/models/advertisement.dart';

class MyAdvertisementCard extends StatelessWidget {
  final Advertisement advertisement;
  final void Function()? onPressedEdit;
  final void Function()? onPressedDelete;
  final bool showActions;

  const MyAdvertisementCard({
    super.key,
    required this.advertisement,
    required this.onPressedEdit,
    required this.onPressedDelete,
    this.showActions = true,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with flexible width
                Expanded(
                  child: Text(
                    advertisement.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  decoration: BoxDecoration(
                    color: advertisement.status == 'approved'
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
                      advertisement.status?.toUpperCase() ?? 'PENDING',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Advertisement description
            Text(
              advertisement.description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Advertisement image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                advertisement.imageUrl,
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 100),
              ),
            ),
            if (showActions) ...[
              const SizedBox(height: 8),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: onPressedEdit,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: onPressedDelete,
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
