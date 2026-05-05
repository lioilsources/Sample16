import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_engine.dart';
import 'sampler_provider.dart';

final globalSpeedProvider = StateProvider<double>((ref) => 1.0);

class PlaybackNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  Future<void> toggle(int index) async {
    final slots = ref.read(samplerProvider);
    final slot = slots[index];
    if (!slot.hasAudio) return;

    if (AudioEngine.instance.isPlaying(index)) {
      await AudioEngine.instance.stop(index);
      state = {...state}..remove(index);
      ref.read(samplerProvider.notifier).setPlaying(index, false);
    } else {
      await AudioEngine.instance.play(slot);
      state = {...state, index};
      ref.read(samplerProvider.notifier).setPlaying(index, true);
    }
  }

  Future<void> playAll() async {
    final slots = ref.read(samplerProvider);
    await AudioEngine.instance.playAll(slots);
    final playing = <int>{};
    for (final slot in slots) {
      if (AudioEngine.instance.isPlaying(slot.index)) {
        playing.add(slot.index);
        ref.read(samplerProvider.notifier).setPlaying(slot.index, true);
      }
    }
    state = playing;
  }

  Future<void> stopAll() async {
    await AudioEngine.instance.stopAll();
    state = {};
    ref.read(samplerProvider.notifier).setAllStopped();
  }

  void setGlobalSpeed(double speed) {
    final slots = ref.read(samplerProvider);
    AudioEngine.instance.setGlobalSpeed(speed, slots);
  }

  bool isPlaying(int index) => state.contains(index);
}

final playbackProvider =
    NotifierProvider<PlaybackNotifier, Set<int>>(PlaybackNotifier.new);
