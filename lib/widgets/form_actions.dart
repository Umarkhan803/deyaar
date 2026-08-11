import 'package:flutter/material.dart';

class FormActions extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onCancel;
  final String cancelLabel;
  final IconData? primaryIcon;

  const FormActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.onCancel,
    this.cancelLabel = 'Cancel',
    this.primaryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onCancel != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              child: Text(cancelLabel),
            ),
          ),
        if (onCancel != null) const SizedBox(width: 12),
        Expanded(
          flex: onCancel == null ? 1 : 1,
          child: ElevatedButton.icon(
            onPressed: onPrimary,
            icon: Icon(primaryIcon ?? Icons.check, size: 18),
            label: Text(primaryLabel),
          ),
        ),
      ],
    );
  }
}
