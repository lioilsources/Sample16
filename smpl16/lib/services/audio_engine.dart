import 'dart:math' as math;
import 'package:flutter_soloud/flutter_soloud.dart';
import '../models/sample_slot.dart';

class AudioEngine {
  AudioEngine._();
  static final instance = AudioEngine._();

  final _sources = <int, AudioSource>{};
  final _handles = <int, SoundHandle>{};
  double _globalSpeed = 1.0;

  double get globalSpeed => _globalSpeed;

  Future<void> play(SampleSlot slot) async {
    if (slot.filePath == null) return;
    await stop(slot.index);

    AudioSource source;
    if (_sources.containsKey(slot.index)) {
      source = _sources[slot.index]!;
    } else {
      source = await SoLoud.instance.loadFile(slot.filePath!);
      _sources[slot.index] = source;
    }

    final handle = await SoLoud.instance.play(source, looping: true);
    _handles[slot.index] = handle;
    SoLoud.instance.setRelativePlaySpeed(handle, _effectiveRate(slot));
  }

  Future<void> stop(int index) async {
    final handle = _handles.remove(index);
    if (handle != null) {
      await SoLoud.instance.stop(handle);
    }
  }

  Future<void> stopAll() async {
    for (final index in _handles.keys.toList()) {
      await stop(index);
    }
  }

  Future<void> playAll(List<SampleSlot> slots) async {
    for (final slot in slots) {
      if (slot.hasAudio && !isPlaying(slot.index)) {
        await play(slot);
      }
    }
  }

  void setGlobalSpeed(double speed, List<SampleSlot> slots) {
    _globalSpeed = speed;
    for (final entry in _handles.entries) {
      final slot = slots.firstWhere(
        (s) => s.index == entry.key,
        orElse: () => SampleSlot(index: entry.key),
      );
      SoLoud.instance.setRelativePlaySpeed(entry.value, _effectiveRate(slot));
    }
  }

  void updateSlotRate(SampleSlot slot) {
    final handle = _handles[slot.index];
    if (handle != null) {
      SoLoud.instance.setRelativePlaySpeed(handle, _effectiveRate(slot));
    }
  }

  bool isPlaying(int index) => _handles.containsKey(index);

  Future<void> disposeSlot(int index) async {
    await stop(index);
    final source = _sources.remove(index);
    if (source != null) {
      await SoLoud.instance.disposeSource(source);
    }
  }

  double _effectiveRate(SampleSlot slot) {
    final pitchFactor =
        slot.pitch == 0.0 ? 1.0 : math.pow(2.0, slot.pitch / 12.0).toDouble();
    return (slot.speed * _globalSpeed * pitchFactor).clamp(0.1, 8.0);
  }
}
