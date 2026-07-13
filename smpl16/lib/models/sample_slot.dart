import 'dart:typed_data';

enum SlotState { empty, loaded, playing, recording }

class SampleSlot {
  final int index;
  String? filePath;
  String? label;
  SlotState state;
  double pitch;        // -12.0 to +12.0 semitones
  double speed;        // 0.25x to 2.0x
  double trimStart;    // 0.0 to 1.0
  double trimEnd;      // 0.0 to 1.0
  bool loop;           // false = one-shot playback
  Duration? duration;
  Float32List? waveformData;

  SampleSlot({
    required this.index,
    this.filePath,
    this.label,
    this.state = SlotState.empty,
    this.pitch = 0.0,
    this.speed = 1.0,
    this.trimStart = 0.0,
    this.trimEnd = 1.0,
    this.loop = false,
    this.duration,
    this.waveformData,
  });

  bool get hasAudio => filePath != null;

  SampleSlot copyWith({
    String? filePath,
    String? label,
    SlotState? state,
    double? pitch,
    double? speed,
    double? trimStart,
    double? trimEnd,
    bool? loop,
    Duration? duration,
    Float32List? waveformData,
    bool clearFile = false,
  }) {
    return SampleSlot(
      index: index,
      filePath: clearFile ? null : (filePath ?? this.filePath),
      label: clearFile ? null : (label ?? this.label),
      state: state ?? this.state,
      pitch: pitch ?? this.pitch,
      speed: speed ?? this.speed,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      loop: loop ?? this.loop,
      duration: clearFile ? null : (duration ?? this.duration),
      waveformData: clearFile ? null : (waveformData ?? this.waveformData),
    );
  }

  Map<String, dynamic> toMap() => {
        'filePath': filePath,
        'label': label,
        'pitch': pitch,
        'speed': speed,
        'trimStart': trimStart,
        'trimEnd': trimEnd,
        'loop': loop,
        'durationMs': duration?.inMilliseconds,
      };

  static SampleSlot fromMap(int index, Map<dynamic, dynamic> map) {
    final durationMs = map['durationMs'] as int?;
    return SampleSlot(
      index: index,
      filePath: map['filePath'] as String?,
      label: map['label'] as String?,
      pitch: (map['pitch'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 1.0,
      trimStart: (map['trimStart'] as num?)?.toDouble() ?? 0.0,
      trimEnd: (map['trimEnd'] as num?)?.toDouble() ?? 1.0,
      loop: map['loop'] as bool? ?? false,
      duration:
          durationMs != null ? Duration(milliseconds: durationMs) : null,
    );
  }
}
