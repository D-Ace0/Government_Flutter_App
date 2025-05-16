import 'package:flutter/material.dart';
import 'package:governmentapp/utils/logger.dart';

class MyButton extends StatelessWidget {
  final void Function()? onTap;
  final String text;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  
  const MyButton({
    super.key, 
    this.onTap, 
    required this.text,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      borderRadius: BorderRadius.circular(8),
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isLoading ? null : () {
          // Log when button is tapped to verify
          AppLogger.d("MyButton: Button '$text' tapped");
          if (onTap != null) {
            onTap!();
          }
        },
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            child: Center(
              child: isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        textColor ?? theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Text(
                    text,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor ?? theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
