import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PitchSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const PitchSlider({super.key, required this.value, required this.onChanged});

  String get _label {
    if (value == 0) return '0 st';
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)} st';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 56,
          child: Text(
            'PITCH',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              color: AppColors.textDim,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: -12.0,
            max: 12.0,
            divisions: 48,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 46,
          child: Text(
            _label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.accent,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
