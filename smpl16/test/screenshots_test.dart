// Store screenshots rendered from the app's own widgets (no device needed).
//
//   SCREENSHOT_DIR=/tmp/shots SCREENSHOT_FONT_DIR=/path/to/fonts \
//     flutter test test/screenshots_test.dart
//
// Skipped unless SCREENSHOT_DIR is set, so CI and `flutter test` ignore it.
//
// The app styles everything with fontFamily 'monospace', which the test
// engine does not have. SCREENSHOT_FONT_DIR must hold DejaVuSansMono.ttf and
// DejaVuSansMono-Bold.ttf (npm package dejavu-fonts-ttf, ttf/): a monospace
// font that also covers the ● ■ ▶ ✕ ∞ ↑ glyphs the UI uses — on a phone those
// come from the system fallback fonts. Roboto and the Material icons are
// loaded from the Flutter SDK cache.
//
// The pads hold real WAV files synthesised below (kick, snare, hats, …); their
// waveforms come from the app's WaveformService.extractFromWav. Providers that
// would touch Hive, SoLoud or the microphone are overridden with fixed state.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smpl16/app.dart';
import 'package:smpl16/models/sample_slot.dart';
import 'package:smpl16/providers/playback_provider.dart';
import 'package:smpl16/providers/recording_provider.dart';
import 'package:smpl16/providers/sampler_provider.dart';
import 'package:smpl16/screens/recording_screen.dart';
import 'package:smpl16/services/waveform_service.dart';
import 'package:smpl16/theme/app_theme.dart';

final _outDir = Platform.environment['SCREENSHOT_DIR'];
final _fontDir = Platform.environment['SCREENSHOT_FONT_DIR'];

const _size = Size(402, 874);
const _ratio = 3.0;

// ---------------------------------------------------------------- fixtures

class _FixedSampler extends SamplerNotifier {
  _FixedSampler(this.slots);
  final List<SampleSlot> slots;
  @override
  List<SampleSlot> build() => slots;
  @override
  Future<void> loadWaveforms() async {}
}

class _FixedPlayback extends PlaybackNotifier {
  _FixedPlayback(this.playing);
  final Set<int> playing;
  @override
  Set<int> build() => playing;
}

class _FixedRecording extends RecordingNotifier {
  _FixedRecording(this.fixed);
  final RecordingState fixed;
  @override
  RecordingState build() => fixed;
}

const _sr = 22050;

Float32List _render(double seconds, double Function(double t) f) {
  final n = (seconds * _sr).round();
  final out = Float32List(n);
  for (var i = 0; i < n; i++) {
    out[i] = f(i / _sr).clamp(-1.0, 1.0);
  }
  return out;
}

final _rng = math.Random(16);
double _noise() => _rng.nextDouble() * 2 - 1;
double _env(double t, double decay) => math.exp(-t / decay);

/// Repeats [hit] at [times] (seconds) inside a [length]-second buffer.
double Function(double) _pattern(
    List<double> times, double Function(double) hit) {
  return (t) {
    var v = 0.0;
    for (final s in times) {
      if (t >= s) v += hit(t - s);
    }
    return v;
  };
}

double _kick(double t) {
  final f = 45 + 80 * _env(t, 0.04);
  return math.sin(2 * math.pi * f * t) * _env(t, 0.22);
}

double _snare(double t) =>
    (0.7 * _noise() + 0.4 * math.sin(2 * math.pi * 185 * t)) * _env(t, 0.09);

double _hat(double t) => _noise() * _env(t, 0.025) * 0.7;

double _syllables(double t, List<double> starts) {
  var v = 0.0;
  for (final s in starts) {
    final d = t - s;
    if (d >= 0 && d < 0.32) {
      final e = math.sin(math.pi * d / 0.32);
      v += e *
          (0.6 * math.sin(2 * math.pi * 170 * t) +
              0.3 * math.sin(2 * math.pi * 340 * t) +
              0.15 * _noise());
    }
  }
  return v * 0.8;
}

final _sounds = <String, Float32List>{
  'kick': _render(0.7, _kick),
  'snare': _render(0.5, _snare),
  'hats': _render(2.0, _pattern([for (var i = 0; i < 16; i++) i * 0.125],
      (t) => _hat(t) * (1 - 0.15 * (t * 8 % 2)))),
  'clap': _render(0.6, _pattern([0, 0.012, 0.024],
      (t) => _noise() * _env(t, 0.05) * 0.5)),
  'bass': _render(2.0, (t) {
    const notes = [0.0, 0.5, 0.75, 1.25, 1.5];
    var v = 0.0;
    for (final s in notes) {
      final d = t - s;
      if (d >= 0 && d < 0.24) {
        v += math.sin(2 * math.pi * 55 * t) * _env(d, 0.12) * 0.95;
      }
    }
    return v;
  }),
  'voice': _render(3.0, (t) => _syllables(t, [0.2, 0.55, 0.9, 1.6, 1.95, 2.4])),
  'perc': _render(0.4, (t) => math.sin(2 * math.pi * 820 * t) * _env(t, 0.06)),
  'stab': _render(1.2, (t) {
    var v = 0.0;
    for (final f in [261.6, 311.1, 392.0]) {
      v += math.sin(2 * math.pi * f * t);
    }
    return v / 3 * _env(t, 0.35);
  }),
  'rim': _render(0.3, (t) =>
      (math.sin(2 * math.pi * 1700 * t) + 0.5 * _noise()) * _env(t, 0.015)),
  'vox': _render(2.0, (t) => _syllables(t, [0.1, 0.45, 1.1, 1.45])),
  'pad': _render(4.0, (t) {
    final swell = math.sin(math.pi * t / 4.0);
    var v = 0.0;
    for (final f in [130.8, 164.8, 196.0, 246.9]) {
      v += math.sin(2 * math.pi * f * t + math.sin(t * 3));
    }
    return v / 4 * swell * (0.75 + 0.25 * math.sin(2 * math.pi * 0.9 * t));
  }),
};

Uint8List _wav(Float32List pcm) {
  final data = ByteData(44 + pcm.length * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + pcm.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, _sr, Endian.little);
  data.setUint32(28, _sr * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, pcm.length * 2, Endian.little);
  for (var i = 0; i < pcm.length; i++) {
    data.setInt16(44 + i * 2, (pcm[i] * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

/// slot index -> (sound, label, loop, pitch, speed); missing = empty pad.
const _layout = <int, (String, String, bool, double, double)>{
  0: ('kick', 'KICK', false, 0, 1),
  1: ('snare', 'SNARE', false, 0, 1),
  2: ('hats', 'HATS', true, 0, 1),
  3: ('clap', 'CLAP', false, 0, 1),
  4: ('bass', 'BASS', true, 3, 1),
  5: ('voice', 'SMP 6', false, 0, 1),
  6: ('perc', 'PERC', false, -5, 1),
  8: ('stab', 'STAB', false, 0, 1),
  9: ('rim', 'RIM', false, 0, 1),
  11: ('vox', 'SMP 12', false, 2, 1.25),
  13: ('pad', 'PAD', true, -12, 0.5),
};

Future<List<SampleSlot>> _slots(Directory tmp, Set<int> playing) async {
  final waveforms = <String, Float32List>{};
  for (final e in _sounds.entries) {
    final f = File('${tmp.path}/${e.key}.wav');
    await f.writeAsBytes(_wav(e.value));
    waveforms[e.key] = (await WaveformService.extractFromWav(f.path))!;
  }
  return [
    for (var i = 0; i < 16; i++)
      if (_layout[i] case (final snd, final label, final loop, final pitch,
          final speed))
        SampleSlot(
          index: i,
          filePath: '${tmp.path}/$snd.wav',
          label: label,
          state: playing.contains(i) ? SlotState.playing : SlotState.loaded,
          loop: loop,
          pitch: pitch,
          speed: speed,
          duration: Duration(
              milliseconds: _sounds[snd]!.length * 1000 ~/ _sr),
          waveformData: waveforms[snd],
        )
      else
        SampleSlot(index: i),
  ];
}

// ---------------------------------------------------------------- harness

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final p in paths) {
      final bytes = await File(p).readAsBytes();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent
          .path;
  final material = '$flutterRoot/bin/cache/artifacts/material_fonts';
  await load('monospace', [
    '$_fontDir/DejaVuSansMono.ttf',
    '$_fontDir/DejaVuSansMono-Bold.ttf',
  ]);
  await load('Roboto', [
    '$material/Roboto-Regular.ttf',
    '$material/Roboto-Medium.ttf',
    '$material/Roboto-Bold.ttf',
  ]);
  await load('MaterialIcons', ['$material/MaterialIcons-Regular.otf']);
}

final _boundary = GlobalKey();

Future<void> _pumpApp(
  WidgetTester tester, {
  required List<SampleSlot> slots,
  Set<int> playing = const {},
  RecordingState recording = const RecordingState(),
  Widget? home,
}) async {
  tester.view.physicalSize = _size * _ratio;
  tester.view.devicePixelRatio = _ratio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: ProviderScope(
        overrides: [
          samplerProvider.overrideWith(() => _FixedSampler(slots)),
          playbackProvider.overrideWith(() => _FixedPlayback(playing)),
          recordingProvider.overrideWith(() => _FixedRecording(recording)),
        ],
        child: home == null
            ? const Smpl16App()
            : MaterialApp(
                theme: AppTheme.dark,
                debugShowCheckedModeBanner: false,
                home: home,
              ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _shoot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 50));
  final boundary = _boundary.currentContext!.findRenderObject()
      as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _ratio);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$_outDir/$name.png')
        .writeAsBytes(png!.buffer.asUint8List());
  });
}

void main() {
  final skip = _outDir == null || _fontDir == null;

  late Directory tmp;
  setUpAll(() async {
    if (skip) return;
    WidgetsApp.debugAllowBannerOverride = false;
    await _loadFonts();
    Directory(_outDir!).createSync(recursive: true);
    tmp = Directory.systemTemp.createTempSync('smpl16_shots');
  });

  Future<List<SampleSlot>> slots(WidgetTester t, Set<int> playing) async =>
      (await t.runAsync(() => _slots(tmp, playing)))!;

  testWidgets('01 pads', (t) async {
    const playing = {1, 2, 4};
    await _pumpApp(t, slots: await slots(t, playing), playing: playing);
    await _shoot(t, '01-pady');
  }, skip: skip);

  testWidgets('02 slot editor', (t) async {
    const playing = {4};
    await _pumpApp(t, slots: await slots(t, playing), playing: playing);
    await t.longPress(find.text('BASS'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    await _shoot(t, '02-editor-slotu');
  }, skip: skip);

  testWidgets('03 recording', (t) async {
    await _pumpApp(
      t,
      slots: await slots(t, const {}),
      recording: const RecordingState(
        phase: RecordingPhase.recording,
        elapsed: Duration(seconds: 4, milliseconds: 370),
        amplitude: 0.62,
      ),
    );
    await _shoot(t, '03-nahravani');
  }, skip: skip);

  testWidgets('04 pick a slot', (t) async {
    await _pumpApp(
      t,
      slots: await slots(t, const {}),
      recording: const RecordingState(
        phase: RecordingPhase.selectSlot,
        pendingPath: '/tmp/rec.wav',
      ),
    );
    await _shoot(t, '04-vyber-slotu');
  }, skip: skip);

  testWidgets('05 record into a slot', (t) async {
    await _pumpApp(
      t,
      slots: await slots(t, const {}),
      recording: const RecordingState(
        phase: RecordingPhase.recording,
        targetSlot: 7,
        elapsed: Duration(seconds: 2, milliseconds: 840),
        amplitude: 0.71,
      ),
      home: const RecordingScreen(targetSlot: 7),
    );
    await _shoot(t, '05-nahravani-do-slotu');
  }, skip: skip);
}
