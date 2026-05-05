import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sampler_provider.dart';
import 'sample_pad.dart';

class PadGrid extends ConsumerWidget {
  final void Function(int index) onLongPress;

  const PadGrid({super.key, required this.onLongPress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(samplerProvider);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: slots.length,
      itemBuilder: (ctx, i) => SamplePad(
        slot: slots[i],
        onLongPress: () => onLongPress(i),
      ),
    );
  }
}
