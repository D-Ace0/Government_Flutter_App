import 'package:flutter/material.dart';
import 'package:governmentapp/models/official_phone.dart';

class OfficialPhoneCard extends StatelessWidget {
  final OfficialPhone phone;
  final void Function()? onPressedEdit;
  final void Function()? onPressedDelete;

  const OfficialPhoneCard({
    super.key,
    required this.phone,
    this.onPressedEdit,
    this.onPressedDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  phone.department,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onPressedEdit != null && onPressedDelete != null)
                Row(
                  children: [
                    IconButton(
                      onPressed: onPressedEdit,
                      icon: const Icon(Icons.edit, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onPressedDelete,
                      icon: const Icon(Icons.delete, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            phone.description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.phone,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                phone.phoneNumber,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
