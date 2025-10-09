import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../utils/platform_utils.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final String description;
  final VoidCallback onPressed;
  final int? number; // For displaying the action number prominently

  const ActionButton({
    super.key,
    required this.text,
    required this.description,
    required this.onPressed,
    this.number,
  });

  @override
  Widget build(BuildContext context) {
    // Extract the action name without the number prefix
    String actionName = text;
    if (text.contains('. ')) {
      actionName = text.split('. ').skip(1).join('. ');
    }

    // Get responsive sizing
    final breakpoint = PlatformUtils.getBreakpoint(context);
    final showNumpadShortcuts =
        PlatformUtils.shouldShowNumpadShortcuts(context);

    // Adjust text length based on screen size
    int maxLength = breakpoint == ResponsiveBreakpoint.mobile ? 10 : 15;
    if (actionName.length > maxLength) {
      actionName = '${actionName.substring(0, maxLength - 3)}...';
    }

    // Get responsive button size
    double buttonHeight = breakpoint == ResponsiveBreakpoint.mobile ? 60 : 75;
    double fontSize = PlatformUtils.getResponsiveFontSize(context, 12);
    double numberSize = breakpoint == ResponsiveBreakpoint.mobile ? 18 : 22;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: buttonHeight,
        // Allow height to expand when text wraps
        minWidth: 60,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.backgroundColor,
          foregroundColor: AppTheme.textColor,
          side: BorderSide(
              color: AppTheme.borderColor, width: AppTheme.borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          elevation: AppTheme.elevation,
          padding:
              EdgeInsets.all(breakpoint == ResponsiveBreakpoint.mobile ? 4 : 6),
        ).copyWith(
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
        child: Stack(
          children: [
            // Corner number badge (desktop/web only)
            if (number != null && showNumpadShortcuts)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: numberSize,
                  height: numberSize,
                  decoration: AppTheme.numberCircleDecoration,
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontSize: fontSize * 0.9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Centered label
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal:
                        breakpoint == ResponsiveBreakpoint.mobile ? 2 : 4),
                child: Text(
                  actionName,
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: fontSize,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: breakpoint == ResponsiveBreakpoint.mobile ? 3 : 2,
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
