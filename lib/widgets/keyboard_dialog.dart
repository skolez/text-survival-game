import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardDialog extends StatefulWidget {
  final String title;
  final List<DialogOption> options;
  final VoidCallback? onCancel;

  const KeyboardDialog({
    super.key,
    required this.title,
    required this.options,
    this.onCancel,
  });

  @override
  State<KeyboardDialog> createState() => _KeyboardDialogState();
}

class DialogOption {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  DialogOption({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
}

class _KeyboardDialogState extends State<KeyboardDialog> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      // Handle number keys 1-9 and numpad 1-9
      for (int i = 0; i < widget.options.length && i < 9; i++) {
        final digitKey = LogicalKeyboardKey.digit1.keyId + i;
        final numpadKey = LogicalKeyboardKey.numpad1.keyId + i;

        if (key.keyId == digitKey || key.keyId == numpadKey) {
          widget.options[i].onTap();
          return KeyEventResult.handled;
        }
      }

      // Handle Escape key to cancel
      if (key == LogicalKeyboardKey.escape) {
        if (widget.onCancel != null) {
          widget.onCancel!();
        } else {
          Navigator.pop(context);
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyPress,
      child: AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...widget.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;

              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(option.icon, color: option.iconColor),
                  ],
                ),
                title: Text(
                  option.title,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: option.onTap,
              );
            }).toList(),
            const SizedBox(height: 16),
            Text(
              "Press 1-${widget.options.length} or use numpad • ESC to cancel",
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: widget.onCancel ?? () => Navigator.pop(context),
            child: const Text("Back", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
