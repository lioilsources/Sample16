import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sample_slot.dart';
import '../theme/app_theme.dart';
import '../providers/playback_provider.dart';
import '../providers/recording_provider.dart';
import 'waveform_painter.dart';

class SamplePad extends ConsumerStatefulWidget {
  final SampleSlot slot;
  final VoidCallback onLongPress;

  const SamplePad({
    super.key,
    required this.slot,
    required this.onLongPress,
  });

  @override
  ConsumerState<SamplePad> createState() => _SamplePadState();
}

class _SamplePadState extends ConsumerState<SamplePad>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SamplePad old) {
    super.didUpdateWidget(old);
    final isPlaying = widget.slot.state == SlotState.playing;
    final wasPlaying = old.slot.state == SlotState.playing;
    if (isPlaying && !wasPlaying) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!isPlaying && wasPlaying) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
    final isRecording = widget.slot.state == SlotState.recording;
    if (isRecording && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  Color get _borderColor {
    switch (widget.slot.state) {
      case SlotState.playing:
        return AppColors.accent;
      case SlotState.recording:
        return AppColors.red;
      case SlotState.loaded:
        return const Color(0xFF2f3a2f);
      case SlotState.empty:
        return AppColors.border;
    }
  }

  Color get _bgColor {
    switch (widget.slot.state) {
      case SlotState.playing:
        return AppColors.padPlaying;
      case SlotState.recording:
        return const Color(0xFF200808);
      case SlotState.loaded:
        return AppColors.padLoaded;
      case SlotState.empty:
        return AppColors.padEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recState = ref.watch(recordingProvider);
    final isSelectMode = recState.isSelectSlot;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isSelectMode) {
          ref.read(recordingProvider.notifier).assignToSlot(widget.slot.index);
        } else {
          ref.read(playbackProvider.notifier).toggle(widget.slot.index);
        }
      },
      onLongPress: isSelectMode ? null : () {
        HapticFeedback.mediumImpact();
        widget.onLongPress();
      },
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          final glowOpacity = widget.slot.state == SlotState.playing
              ? 0.1 + _pulseAnim.value * 0.15
              : widget.slot.state == SlotState.recording
                  ? 0.1 + _pulseAnim.value * 0.2
                  : 0.0;

          final glowColor = widget.slot.state == SlotState.recording
              ? AppColors.red
              : AppColors.accent;

          return Container(
            decoration: BoxDecoration(
              color: _bgColor,
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(6),
              boxShadow: glowOpacity > 0
                  ? [
                      BoxShadow(
                        color: glowColor.withAlpha((glowOpacity * 255).toInt()),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Gloss overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withAlpha(8),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.5],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PadNumber(
                        number: widget.slot.index + 1,
                        playing: widget.slot.state == SlotState.playing,
                      ),
                      const Spacer(),
                      if (widget.slot.waveformData != null) ...[
                        SizedBox(
                          height: 24,
                          child: CustomPaint(
                            painter: WaveformPainter(
                              data: widget.slot.waveformData,
                              color: widget.slot.state == SlotState.playing
                                  ? AppColors.accent
                                  : AppColors.textDim,
                              glow: false,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ] else ...[
                        Center(
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontSize: 20,
                              color: AppColors.textDim.withAlpha(100),
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                      if (widget.slot.hasAudio) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.slot.label ?? 'SMP ${widget.slot.index + 1}',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: widget.slot.state == SlotState.playing
                                      ? AppColors.accent
                                      : AppColors.textDim,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.slot.duration != null)
                              Text(
                                '${widget.slot.duration!.inSeconds}s',
                                style: TextStyle(
                                  fontSize: 7,
                                  color: widget.slot.state == SlotState.playing
                                      ? AppColors.accent.withAlpha(180)
                                      : AppColors.textDim.withAlpha(120),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PadNumber extends StatelessWidget {
  final int number;
  final bool playing;

  const _PadNumber({required this.number, required this.playing});

  @override
  Widget build(BuildContext context) {
    return Text(
      number.toString().padLeft(2, '0'),
      style: TextStyle(
        fontSize: 9,
        color: playing ? AppColors.accent : AppColors.textDim,
        fontFamily: 'monospace',
        letterSpacing: 1,
      ),
    );
  }
}
