import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/recording_provider.dart';
import '../widgets/waveform_painter.dart';

class RecordingScreen extends ConsumerWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'NAHRÁVÁNÍ',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            letterSpacing: 4,
            color: AppColors.text,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDim),
          onPressed: () {
            ref.read(recordingProvider.notifier).cancel();
            Navigator.pop(context);
          },
        ),
        backgroundColor: AppColors.bg,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Spacer(),
            // Timer display
            _ElapsedTimer(state: state),
            const SizedBox(height: 24),
            // Live amplitude visualizer
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(
                  color: state.isRecording
                      ? AppColors.red.withAlpha(100)
                      : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CustomPaint(
                  painter: LiveAmplitudePainter(amplitude: state.amplitude),
                  size: Size.infinite,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Record / Stop button
            _RecordButton(state: state),
            const Spacer(),
            // Status text
            Text(
              state.isRecording
                  ? 'NAHRÁVÁ SE  ·  MAX 30s'
                  : state.isSelectSlot
                      ? 'HOTOVO  ·  ZAVŘI A VYBER SLOT'
                      : 'KLEPNI ● PRO SPUŠTĚNÍ',
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: AppColors.textDim,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ElapsedTimer extends StatelessWidget {
  final RecordingState state;
  const _ElapsedTimer({required this.state});

  @override
  Widget build(BuildContext context) {
    final d = state.elapsed;
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    final cs = ((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');

    return Text(
      '$mm:$ss.$cs',
      style: TextStyle(
        fontSize: 48,
        fontFamily: 'monospace',
        letterSpacing: 4,
        color: state.isRecording ? AppColors.red : AppColors.text,
      ),
    );
  }
}

class _RecordButton extends ConsumerWidget {
  final RecordingState state;
  const _RecordButton({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (state.isRecording) {
          ref.read(recordingProvider.notifier).stopRecording();
        } else if (!state.isSelectSlot) {
          ref.read(recordingProvider.notifier).startRecording();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: state.isRecording
              ? AppColors.red
              : AppColors.red.withAlpha(20),
          border: Border.all(
            color: AppColors.red,
            width: state.isRecording ? 3 : 1.5,
          ),
          boxShadow: state.isRecording
              ? [
                  BoxShadow(
                    color: AppColors.red.withAlpha(100),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: state.isRecording
              ? Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : const Text(
                  '●',
                  style: TextStyle(
                    fontSize: 36,
                    color: AppColors.red,
                  ),
                ),
        ),
      ),
    );
  }
}
