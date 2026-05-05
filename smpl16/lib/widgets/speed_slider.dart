import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpeedSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const SpeedSlider({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 56,
          child: Text(
            'SPEED',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              color: AppColors.textDim,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.accent2,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.accent2,
              overlayColor: AppColors.accent2.withAlpha(40),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 2,
            ),
            child: Slider(
              value: value,
              min: 0.25,
              max: 2.0,
              divisions: 70,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 46,
          child: Text(
            '${value.toStringAsFixed(2)}×',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.accent2,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
