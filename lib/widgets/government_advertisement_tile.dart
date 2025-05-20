import 'package:flutter/material.dart';
import 'package:governmentapp/models/advertisement.dart';
import 'package:governmentapp/widgets/government_advertisement_card.dart';

class GovernmentAdvertisementTile extends StatelessWidget {
  final Advertisement advertisement;
  final void Function()? onPressedApprove;
  final void Function()? onPressedReject;
  final String status;
  final void Function()? onPressedEdit;

  const GovernmentAdvertisementTile({
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GovernmentAdvertisementCard(
        advertisement: advertisement,
        status: status,
        onPressedApprove: onPressedApprove,
        onPressedReject: onPressedReject,
        onPressedEdit: onPressedEdit,
      ),
    );
  }
}
