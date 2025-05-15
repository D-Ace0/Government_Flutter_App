import 'package:flutter/material.dart';

enum ActionButtonStyle {
  primary,  // Blue
  success,  // Green
  danger,   // Red
  warning,  // Amber
  info,     // Light Blue
  neutral   // Grey
}

enum ActionButtonSize {
  small,
  medium,
  large
}

class MyActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final void Function()? onTap;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final ActionButtonStyle style;
  final bool isOutlined;
  final bool useGradient;
  final double elevation;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool isLoading;

  const MyActionButton({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.style = ActionButtonStyle.primary,
    this.isOutlined = false,
    this.useGradient = false,
    this.elevation = 1,
    this.borderRadius = 8.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Define base colors for each style
    final Map<ActionButtonStyle, Color> baseColors = {
      ActionButtonStyle.primary: Colors.blue.shade600,
      ActionButtonStyle.success: Colors.green.shade600,
      ActionButtonStyle.danger: Colors.red.shade600,
      ActionButtonStyle.warning: Colors.amber.shade600,
      ActionButtonStyle.info: Colors.lightBlue.shade500,
      ActionButtonStyle.neutral: Colors.grey.shade600,
    };
    
    // Get base color for current style
    final Color baseColor = backgroundColor ?? baseColors[style]!;
    
    // Determine text and icon colors
    final Color buttonTextColor = textColor ?? 
        (isOutlined ? baseColor : Colors.white);
    final Color buttonIconColor = iconColor ?? buttonTextColor;
    
    // Define gradient colors if enabled
    final List<Color> gradientColors = useGradient 
        ? [baseColor, baseColor.withAlpha(204)] // 0.8 opacity = 204 alpha
        : [baseColor, baseColor];
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: baseColor.withAlpha(25), // 0.1 opacity = 25 alpha
        highlightColor: baseColor.withAlpha(13), // 0.05 opacity = 13 alpha
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isOutlined ? Colors.transparent : null,
            gradient: isOutlined ? null : LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: isOutlined 
                ? Border.all(color: baseColor, width: 1.5) 
                : null,
            boxShadow: isOutlined ? null : [
              BoxShadow(
                color: baseColor.withAlpha(76), // 0.3 opacity = 76 alpha
                blurRadius: elevation * 3,
                offset: Offset(0, elevation),
              ),
            ],
          ),
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(buttonTextColor),
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: buttonIconColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      title,
                      style: TextStyle(
                        color: buttonTextColor,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// A specialized button for the Republish action with a professional look
class RepublishButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final ActionButtonSize size;
  
  const RepublishButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.size = ActionButtonSize.medium,
  });
  
  @override
  Widget build(BuildContext context) {
    // Define sizing based on button size
    final Map<ActionButtonSize, Map<String, dynamic>> sizingProps = {
      ActionButtonSize.small: {
        'padding': const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        'fontSize': 12.0,
        'iconSize': 16.0,
        'borderRadius': 16.0,
      },
      ActionButtonSize.medium: {
        'padding': const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        'fontSize': 14.0,
        'iconSize': 18.0,
        'borderRadius': 20.0,
      },
      ActionButtonSize.large: {
        'padding': const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        'fontSize': 16.0,
        'iconSize': 20.0,
        'borderRadius': 24.0,
      },
    };
    
    final props = sizingProps[size]!;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(props['borderRadius']),
        splashColor: Colors.green.shade700.withAlpha(76), // 0.3 opacity = 76 alpha
        highlightColor: Colors.green.shade700.withAlpha(25), // 0.1 opacity = 25 alpha
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade600,
                Colors.green.shade500,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(props['borderRadius']),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade700.withAlpha(76), // 0.3 opacity = 76 alpha
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: props['padding'],
            child: isLoading
                ? SizedBox(
                    width: props['iconSize'],
                    height: props['iconSize'],
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restart_alt_rounded,
                        color: Colors.white,
                        size: props['iconSize'],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Republish',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: props['fontSize'],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// A standardized action button with consistent styling for the application
class StandardActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final ActionButtonStyle style;
  final bool isOutlined;
  final bool isLoading;
  final ActionButtonSize size;
  
  const StandardActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.style = ActionButtonStyle.primary,
    this.isOutlined = false,
    this.isLoading = false,
    this.size = ActionButtonSize.medium,
  });
  
  @override
  Widget build(BuildContext context) {
    // Define base colors for each style
    final Map<ActionButtonStyle, Color> baseColors = {
      ActionButtonStyle.primary: Colors.blue.shade600,
      ActionButtonStyle.success: Colors.green.shade600,
      ActionButtonStyle.danger: Colors.red.shade600,
      ActionButtonStyle.warning: Colors.amber.shade600,
      ActionButtonStyle.info: Colors.lightBlue.shade500,
      ActionButtonStyle.neutral: Colors.grey.shade600,
    };
    
    // Define sizing based on button size
    final Map<ActionButtonSize, Map<String, dynamic>> sizingProps = {
      ActionButtonSize.small: {
        'padding': const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        'fontSize': 12.0,
        'iconSize': 16.0,
        'borderRadius': 16.0,
      },
      ActionButtonSize.medium: {
        'padding': const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        'fontSize': 14.0,
        'iconSize': 18.0,
        'borderRadius': 20.0,
      },
      ActionButtonSize.large: {
        'padding': const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        'fontSize': 16.0,
        'iconSize': 20.0,
        'borderRadius': 24.0,
      },
    };
    
    final Color baseColor = baseColors[style]!;
    final props = sizingProps[size]!;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(props['borderRadius']),
        splashColor: baseColor.withAlpha(76), // 0.3 opacity = 76 alpha
        highlightColor: baseColor.withAlpha(25), // 0.1 opacity = 25 alpha
        child: Container(
          decoration: BoxDecoration(
            color: isOutlined ? Colors.transparent : null,
            gradient: isOutlined 
                ? null 
                : LinearGradient(
                    colors: [baseColor, baseColor.withAlpha(217)], // 0.85 opacity = 217 alpha
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: BorderRadius.circular(props['borderRadius']),
            border: isOutlined ? Border.all(color: baseColor, width: 1.5) : null,
            boxShadow: isOutlined 
                ? null 
                : [
                    BoxShadow(
                      color: baseColor.withAlpha(76), // 0.3 opacity = 76 alpha
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: props['padding'],
          child: isLoading
              ? SizedBox(
                  width: props['iconSize'],
                  height: props['iconSize'],
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOutlined ? baseColor : Colors.white
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: isOutlined ? baseColor : Colors.white,
                      size: props['iconSize'],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isOutlined ? baseColor : Colors.white,
                        fontSize: props['fontSize'],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
