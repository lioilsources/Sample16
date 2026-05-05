import 'dart:async';
import 'package:record/record.dart';
import 'file_service.dart';

class RecorderService {
  RecorderService._();
  static final instance = RecorderService._();

  final _recorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _startTime;
  StreamSubscription<Amplitude>? _ampSub;
  final _amplitudeController = StreamController<double>.broadcast();

  bool get isRecording => _isRecording;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  Duration get elapsed =>
      _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<String?> start() async {
    if (_isRecording) return null;
    if (!await hasPermission()) return null;

    final path = await FileService.tempRecordingPath();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: path,
    );

    _isRecording = true;
    _startTime = DateTime.now();

    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 50))
        .listen((amp) {
      final normalised = ((amp.current + 60) / 60).clamp(0.0, 1.0);
      _amplitudeController.add(normalised);
    });

    return path;
  }

  Future<String?> stop() async {
    if (!_isRecording) return null;
    await _ampSub?.cancel();
    _ampSub = null;
    _isRecording = false;
    _startTime = null;
    return _recorder.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _amplitudeController.close();
    _recorder.dispose();
  }
}
