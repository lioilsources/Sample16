import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/sampler_provider.dart';
import '../providers/recording_provider.dart';
import '../widgets/pad_grid.dart';
import '../widgets/transport_bar.dart';
import 'slot_editor_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(samplerProvider.notifier).loadWaveforms();
    });
  }

  void _openEditor(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SlotEditorScreen(slotIndex: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recState = ref.watch(recordingProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const _Header(),
              const SizedBox(height: 10),

              // Status bar
              _StatusBar(recState: recState),
              const SizedBox(height: 12),

              // Pad grid
              PadGrid(onLongPress: _openEditor),
              const SizedBox(height: 12),

              // Select slot banner (shown after recording)
              if (recState.isSelectSlot) ...[
                _SelectSlotBanner(
                  onCancel: () =>
                      ref.read(recordingProvider.notifier).cancel(),
                ),
                const SizedBox(height: 12),
              ],

              // Transport bar
              const TransportBar(),
              const SizedBox(height: 8),

              // Footer
              const Center(
                child: Text(
                  'SMPL–16  ·  v1.0',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: AppColors.textDim,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
              color: AppColors.accent,
            ),
            children: [
              TextSpan(text: 'SMPL'),
              TextSpan(
                text: '–16',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const Text(
          'SAMPLER\nv1.0',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 2,
            color: AppColors.textDim,
            fontFamily: 'monospace',
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  final RecordingState recState;
  const _StatusBar({required this.recState});

  Color get _borderColor {
    if (recState.isRecording) return AppColors.red;
    if (recState.isSelectSlot) return AppColors.accent2;
    return AppColors.border;
  }

  Color get _textColor {
    if (recState.isRecording) return AppColors.red;
    if (recState.isSelectSlot) return AppColors.accent2;
    return AppColors.textDim;
  }

  String get _text {
    if (recState.isRecording) {
      final d = recState.elapsed;
      final mm = d.inMinutes.toString().padLeft(2, '0');
      final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '● NAHRÁVÁM  $mm:$ss';
    }
    if (recState.isSelectSlot) return '● NAHRÁVKA PŘIPRAVENA  ·  KLEPNI NA SLOT';
    return 'PŘIPRAVEN  ·  TAP = PLAY  ·  HOLD = EDITOVAT';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _text,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                color: _textColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectSlotBanner extends StatelessWidget {
  final VoidCallback onCancel;
  const _SelectSlotBanner({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent2.withAlpha(20),
        border: Border.all(color: AppColors.accent2.withAlpha(180)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'KLEPNI NA PAD PRO PŘIŘAZENÍ NAHRÁVKY',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: AppColors.accent2,
                fontFamily: 'monospace',
              ),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: const Text(
              '✕',
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
