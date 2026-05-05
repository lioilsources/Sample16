import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sample_slot.dart';
import '../services/audio_engine.dart';
import '../services/waveform_service.dart';
import '../services/file_service.dart';

const _boxName = 'smpl16_slots';
const _numSlots = 16;

class SamplerNotifier extends Notifier<List<SampleSlot>> {
  late Box _box;

  @override
  List<SampleSlot> build() {
    _box = Hive.box(_boxName);
    return List.generate(_numSlots, (i) {
      final saved = _box.get(i.toString());
      if (saved is Map) {
        return SampleSlot.fromMap(i, saved);
      }
      return SampleSlot(index: i);
    });
  }

  /// Loads waveform data for slots that have a filePath but no waveformData.
  Future<void> loadWaveforms() async {
    for (final slot in state) {
      if (slot.hasAudio && slot.waveformData == null) {
        final wf = await _loadWaveform(slot.filePath!);
        _updateSlot(slot.index, (s) => s.copyWith(waveformData: wf));
      }
    }
  }

  Future<void> assignRecording(int index, String filePath) async {
    final wf = await _loadWaveform(filePath);
    final dest = await FileService.importFile(filePath, index);

    final old = state[index];
    if (old.hasAudio) {
      AudioEngine.instance.disposeSlot(index);
      await FileService.deleteFile(old.filePath);
    }

    _updateSlot(index, (_) => SampleSlot(
          index: index,
          filePath: dest,
          label: 'SMP ${index + 1}',
          state: SlotState.loaded,
          waveformData: wf,
        ));
    _persist(index);
  }

  Future<void> importFile(int index, String sourcePath) async {
    final dest = await FileService.importFile(sourcePath, index);
    final wf = await _loadWaveform(dest);

    final old = state[index];
    if (old.hasAudio) {
      await AudioEngine.instance.disposeSlot(index);
      await FileService.deleteFile(old.filePath);
    }

    _updateSlot(index, (_) => SampleSlot(
          index: index,
          filePath: dest,
          label: sourcePath.split('/').last.replaceAll(RegExp(r'\.\w+$'), ''),
          state: SlotState.loaded,
          waveformData: wf,
        ));
    _persist(index);
  }

  void updatePitch(int index, double pitch) {
    _updateSlot(index, (s) => s.copyWith(pitch: pitch));
    AudioEngine.instance.updateSlotRate(state[index]);
    _persist(index);
  }

  void updateSpeed(int index, double speed) {
    _updateSlot(index, (s) => s.copyWith(speed: speed));
    AudioEngine.instance.updateSlotRate(state[index]);
    _persist(index);
  }

  void updateLabel(int index, String label) {
    _updateSlot(index, (s) => s.copyWith(label: label));
    _persist(index);
  }

  void setPlaying(int index, bool playing) {
    _updateSlot(
      index,
      (s) => s.copyWith(state: playing ? SlotState.playing : SlotState.loaded),
    );
  }

  void setAllStopped() {
    state = [
      for (final s in state)
        if (s.state == SlotState.playing)
          s.copyWith(state: SlotState.loaded)
        else
          s,
    ];
  }

  Future<void> clearSlot(int index) async {
    final slot = state[index];
    await AudioEngine.instance.disposeSlot(index);
    await FileService.deleteFile(slot.filePath);
    _updateSlot(index, (_) => SampleSlot(index: index));
    _box.delete(index.toString());
  }

  void _updateSlot(int index, SampleSlot Function(SampleSlot) updater) {
    final updated = List<SampleSlot>.from(state);
    updated[index] = updater(state[index]);
    state = updated;
  }

  void _persist(int index) {
    _box.put(index.toString(), state[index].toMap());
  }

  Future<Float32List> _loadWaveform(String path) async {
    if (path.toLowerCase().endsWith('.wav')) {
      return await WaveformService.extractFromWav(path) ??
          WaveformService.generateFake();
    }
    return WaveformService.generateFake();
  }
}

final samplerProvider =
    NotifierProvider<SamplerNotifier, List<SampleSlot>>(SamplerNotifier.new);

final slotProvider = Provider.family<SampleSlot, int>(
  (ref, index) => ref.watch(samplerProvider)[index],
);
