import 'package:flutter/material.dart';

import '../constants/app_theme.dart';

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

    // Truncate long action names
    if (actionName.length > 15) {
      actionName = '${actionName.substring(0, 12)}...';
    }

    return SizedBox(
      height: 75, // Fixed height for consistency
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.backgroundColor,
          foregroundColor: AppTheme.textColor,
          side: const BorderSide(
              color: AppTheme.borderColor, width: AppTheme.borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          elevation: AppTheme.elevation,
          padding: const EdgeInsets.all(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prominent number display
            if (number != null)
              Container(
                width: 22,
                height: 22,
                decoration: AppTheme.numberCircleDecoration,
                child: Center(
                  child: Text(
                    number.toString(),
                    style: AppTheme.labelTextStyle,
                  ),
                ),
              ),
            const SizedBox(height: 3),

            // Action name
            Expanded(
              child: Text(
                actionName,
                style: AppTheme.smallTextStyle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
