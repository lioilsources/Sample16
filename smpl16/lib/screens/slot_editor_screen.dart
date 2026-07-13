import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/sample_slot.dart';
import '../theme/app_theme.dart';
import '../providers/sampler_provider.dart';
import '../providers/playback_provider.dart';
import '../widgets/waveform_painter.dart';
import '../widgets/pitch_slider.dart';
import '../widgets/speed_slider.dart';
import 'recording_screen.dart';

class SlotEditorScreen extends ConsumerStatefulWidget {
  final int slotIndex;

  const SlotEditorScreen({super.key, required this.slotIndex});

  @override
  ConsumerState<SlotEditorScreen> createState() => _SlotEditorScreenState();
}

class _SlotEditorScreenState extends ConsumerState<SlotEditorScreen> {
  SampleSlot get _slot => ref.watch(samplerProvider)[widget.slotIndex];

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    await ref
        .read(samplerProvider.notifier)
        .importFile(widget.slotIndex, result.files.single.path!);
  }

  Future<void> _openRecording() async {
    // Recording started from the editor is assigned straight to this slot.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordingScreen(targetSlot: widget.slotIndex),
      ),
    );
  }

  Future<void> _clearSlot() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'SMAZAT SLOT',
          style: TextStyle(
            fontFamily: 'monospace',
            letterSpacing: 2,
            color: AppColors.text,
            fontSize: 14,
          ),
        ),
        content: Text(
          'Smazat obsah slotu ${widget.slotIndex + 1}?',
          style: const TextStyle(color: AppColors.textDim, fontFamily: 'monospace'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ZRUŠIT',
                style: TextStyle(color: AppColors.textDim, fontFamily: 'monospace')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SMAZAT',
                style: TextStyle(color: AppColors.red, fontFamily: 'monospace')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(samplerProvider.notifier).clearSlot(widget.slotIndex);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slot = _slot;
    final isPlaying = ref.watch(playbackProvider).contains(widget.slotIndex);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    letterSpacing: 3,
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    const TextSpan(text: 'SLOT '),
                    TextSpan(
                      text: (widget.slotIndex + 1).toString().padLeft(2, '0'),
                      style: const TextStyle(color: AppColors.accent),
                    ),
                    if (isPlaying)
                      const TextSpan(
                        text: '  ●  HRAJE',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    '✕ ZAVŘÍT',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textDim,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Waveform
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: slot.waveformData != null
                  ? CustomPaint(
                      painter: WaveformPainter(data: slot.waveformData),
                      size: Size.infinite,
                    )
                  : const Center(
                      child: Text(
                        'ŽÁDNÝ ZVUK  ·  NAHRAJ NEBO IMPORTUJ',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textDim,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: '● NAHRÁT',
                  color: AppColors.red,
                  onTap: _openRecording,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: '↑ IMPORTOVAT',
                  color: AppColors.textDim,
                  onTap: _importFile,
                ),
              ),
              if (slot.hasAudio) ...[
                const SizedBox(width: 8),
                _ActionBtn(
                  label: '✕',
                  color: AppColors.red,
                  onTap: _clearSlot,
                  flex: 0,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Controls
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                // Changes apply (and are heard) immediately.
                PitchSlider(
                  value: slot.pitch,
                  onChanged: (v) => ref
                      .read(samplerProvider.notifier)
                      .updatePitch(widget.slotIndex, v),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(color: AppColors.border, height: 1),
                ),
                SpeedSlider(
                  value: slot.speed,
                  onChanged: (v) => ref
                      .read(samplerProvider.notifier)
                      .updateSpeed(widget.slotIndex, v),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(color: AppColors.border, height: 1),
                ),
                _LoopToggle(
                  value: slot.loop,
                  onChanged: (v) => ref
                      .read(samplerProvider.notifier)
                      .updateLoop(widget.slotIndex, v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LoopToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LoopToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 56,
          child: Text(
            'LOOP',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              color: AppColors.textDim,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value ? 'HRAJE DOKOLA' : 'ZAHRAJE JEDNOU',
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1,
              color: AppColors.textDim,
              fontFamily: 'monospace',
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: value
                  ? AppColors.accent.withAlpha(26)
                  : Colors.transparent,
              border: Border.all(
                color: value ? AppColors.accent : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value ? '∞ ON' : 'OFF',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                fontFamily: 'monospace',
                color: value ? AppColors.accent : AppColors.textDim,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int flex;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
            letterSpacing: 1.5,
            fontFamily: 'monospace',
            color: color,
          ),
        ),
      ),
    );
    return flex == 0 ? btn : btn;
  }
}
