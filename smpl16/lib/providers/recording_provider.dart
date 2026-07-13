import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recorder_service.dart';
import 'sampler_provider.dart';

enum RecordingPhase { idle, recording, selectSlot, assigned }

class RecordingState {
  final RecordingPhase phase;
  final String? pendingPath;
  final int? targetSlot;
  final Duration elapsed;
  final double amplitude;

  const RecordingState({
    this.phase = RecordingPhase.idle,
    this.pendingPath,
    this.targetSlot,
    this.elapsed = Duration.zero,
    this.amplitude = 0.0,
  });

  bool get isRecording => phase == RecordingPhase.recording;
  bool get isSelectSlot => phase == RecordingPhase.selectSlot;

  RecordingState copyWith({
    RecordingPhase? phase,
    String? pendingPath,
    int? targetSlot,
    Duration? elapsed,
    double? amplitude,
  }) =>
      RecordingState(
        phase: phase ?? this.phase,
        pendingPath: pendingPath ?? this.pendingPath,
        targetSlot: targetSlot ?? this.targetSlot,
        elapsed: elapsed ?? this.elapsed,
        amplitude: amplitude ?? this.amplitude,
      );
}

class RecordingNotifier extends Notifier<RecordingState> {
  Timer? _timer;
  StreamSubscription<double>? _ampSub;

  @override
  RecordingState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _ampSub?.cancel();
    });
    return const RecordingState();
  }

  /// When [targetSlot] is set, the finished recording is assigned to that
  /// slot directly instead of entering the select-slot phase.
  Future<bool> startRecording({int? targetSlot}) async {
    final svc = RecorderService.instance;
    if (!await svc.hasPermission()) return false;

    final path = await svc.start();
    if (path == null) return false;

    state = RecordingState(
      phase: RecordingPhase.recording,
      targetSlot: targetSlot,
      elapsed: Duration.zero,
    );

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final elapsed = svc.elapsed;
      state = state.copyWith(elapsed: elapsed);
      if (elapsed.inSeconds >= 30) stopRecording();
    });

    _ampSub = svc.amplitudeStream.listen((amp) {
      state = state.copyWith(amplitude: amp);
    });

    return true;
  }

  Future<void> stopRecording() async {
    _timer?.cancel();
    _timer = null;
    await _ampSub?.cancel();
    _ampSub = null;

    final path = await RecorderService.instance.stop();
    final target = state.targetSlot;
    if (path == null) {
      state = const RecordingState();
    } else if (target != null) {
      await ref.read(samplerProvider.notifier).assignRecording(target, path);
      state = const RecordingState(phase: RecordingPhase.assigned);
    } else {
      state = RecordingState(
        phase: RecordingPhase.selectSlot,
        pendingPath: path,
      );
    }
  }

  /// Acknowledge the [RecordingPhase.assigned] state (UI has reacted).
  void consumeAssigned() {
    state = const RecordingState();
  }

  Future<void> assignToSlot(int index) async {
    final path = state.pendingPath;
    if (path == null) return;
    state = const RecordingState();
    await ref.read(samplerProvider.notifier).assignRecording(index, path);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    RecorderService.instance.stop();
    state = const RecordingState();
  }
}

final recordingProvider =
    NotifierProvider<RecordingNotifier, RecordingState>(RecordingNotifier.new);
