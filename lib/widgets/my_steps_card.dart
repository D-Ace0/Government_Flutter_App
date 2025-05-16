import 'package:flutter/material.dart';

class MyStepsCard extends StatelessWidget {
  final List<String> steps;
  const MyStepsCard({super.key, required this.steps});

  void _showStepsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Advertisement Guidelines",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  steps.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _getStepColor(index),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            steps[index],
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextButton.icon(
        onPressed: () => _showStepsDialog(context),
        icon: Icon(
          Icons.info_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: Text(
          "View Guidelines",
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Color _getStepColor(int index) {
    final colors = [
      Colors.blue,
      Colors.blue.shade700,
      Colors.indigo,
      Colors.indigo.shade700,
    ];
    return colors[index % colors.length];
  }
}
