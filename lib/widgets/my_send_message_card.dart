import 'package:flutter/material.dart';
import 'package:governmentapp/widgets/my_action_button.dart';
import 'package:governmentapp/widgets/my_text_field.dart';

class MySendMessageCard extends StatelessWidget {
  final TextEditingController subjectController;
  final TextEditingController messageController;
  final void Function()? onTap;
  const MySendMessageCard({
    super.key,
    required this.subjectController,
    required this.messageController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Theme.of(context).colorScheme.tertiary,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Send Message to Government",
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          MyTextfield(
            hintText: "Subject",
            obSecure: false,
            controller: subjectController,
          ),
          const SizedBox(height: 8),
          MyTextfield(
            hintText: "Type your message here",
            obSecure: false,
            controller: messageController,
          ),
          const SizedBox(height: 8),
          MyActionButton(
            title: "Send Message",
            icon: Icons.send_outlined,
            textColor: Theme.of(context).colorScheme.tertiary,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
