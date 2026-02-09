import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int value;           
  final double average;       
  final bool readOnly;
  final ValueChanged<int>? onChanged;

  const StarRating({
    super.key,
    required this.value,
    required this.average,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 1; i <= 5; i++)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: readOnly ? null : () => onChanged?.call(i),
            icon: Icon(
              i <= value ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 24,
            ),
          ),
        const SizedBox(width: 8),
        Text(average.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
