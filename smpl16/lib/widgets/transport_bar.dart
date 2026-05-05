import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/playback_provider.dart';
import '../providers/recording_provider.dart';

class TransportBar extends ConsumerWidget {
  const TransportBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalSpeed = ref.watch(globalSpeedProvider);
    final recState = ref.watch(recordingProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // Global speed row
          Row(
            children: [
              const _Label('LOOP SPD'),
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
                    value: globalSpeed,
                    min: 0.25,
                    max: 2.0,
                    onChanged: (v) {
                      ref.read(globalSpeedProvider.notifier).state = v;
                      ref.read(playbackProvider.notifier).setGlobalSpeed(v);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 46,
                child: Text(
                  '${globalSpeed.toStringAsFixed(2)}×',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accent2,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const _Divider(),
          // Transport buttons row
          Row(
            children: [
              // REC button
              _RecGlobalButton(isRecording: recState.isRecording),
              const SizedBox(width: 8),
              // PLAY ALL
              Expanded(
                child: _TransportBtn(
                  label: '▶  PLAY ALL',
                  color: AppColors.accent,
                  onTap: () => ref.read(playbackProvider.notifier).playAll(),
                ),
              ),
              const SizedBox(width: 8),
              // STOP ALL
              Expanded(
                child: _TransportBtn(
                  label: '■  STOP',
                  color: AppColors.textDim,
                  onTap: () => ref.read(playbackProvider.notifier).stopAll(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecGlobalButton extends ConsumerWidget {
  final bool isRecording;
  const _RecGlobalButton({required this.isRecording});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (isRecording) {
          ref.read(recordingProvider.notifier).stopRecording();
        } else {
          ref.read(recordingProvider.notifier).startRecording();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isRecording ? AppColors.red : Colors.transparent,
          border: Border.all(
            color: isRecording ? AppColors.red : AppColors.red.withAlpha(180),
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isRecording
              ? [
                  BoxShadow(
                    color: AppColors.red.withAlpha(80),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Text(
          '● REC',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2,
            fontFamily: 'monospace',
            color: isRecording ? Colors.white : AppColors.red,
          ),
        ),
      ),
    );
  }
}

class _TransportBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TransportBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(13),
          border: Border.all(color: color.withAlpha(180)),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2,
            fontFamily: 'monospace',
            color: color,
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          letterSpacing: 2,
          color: AppColors.textDim,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: AppColors.border, height: 1),
    );
  }
}
