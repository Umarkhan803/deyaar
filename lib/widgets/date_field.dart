import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class DateField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool optional;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final initial = value.isNotEmpty
            ? DateTime.tryParse(value) ?? DateTime.now()
            : DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2018),
          lastDate: DateTime(2040),
        );
        if (picked != null) {
          onChanged(Formatters.toIso(picked));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: optional ? '$label (optional)' : label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value.isEmpty ? 'Select date' : Formatters.dateDisplay(value),
          style: TextStyle(
            color: value.isEmpty ? Colors.grey : null,
          ),
        ),
      ),
    );
  }
}
