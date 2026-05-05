# SMPL-16 — Flutter Sampler App
> Plán pro Claude Code

---

## Přehled projektu

16-slotový mobilní sampler. Každý slot může obsahovat nahraný nebo importovaný zvuk, který se přehrává v loopu s nastavitelnou rychlostí a výškou tónu.

**Platforma:** iOS (primárně), Android (sekundárně)  
**Framework:** Flutter (Dart)  
**Stav:** plán v0.1, připraven k implementaci

---

## Technický stack

| Vrstva | Balíček | Poznámka |
|---|---|---|
| Audio přehrávání | `just_audio` | loop, speed control |
| Nahrávání | `record` | mic access, WAV/M4A output |
| Pitch shifting | `flutter_soloud` | real-time DSP, ARM64 ok |
| Waveform vizualizace | custom `CustomPainter` | z PCM dat |
| Správa stavu | `riverpod` | `AsyncNotifier` per slot |
| Persistece | `hive` nebo `isar` | slot metadata, cesty k souborům |
| Oprávnění | `permission_handler` | mikrofon, úložiště |
| Haptika | `haptic_feedback` (Flutter SDK) | tap feedback na pady |

---

## Datový model

```dart
// lib/models/sample_slot.dart

enum SlotState { empty, loaded, playing, recording }

class SampleSlot {
  final int index;           // 0–15
  String? filePath;          // absolutní cesta k audio souboru
  String? label;             // volitelný název
  SlotState state;
  double pitch;              // -12.0 až +12.0 semitónů, default 0.0
  double speed;              // 0.25x až 2.0x, default 1.0
  double trimStart;          // 0.0–1.0 relativní pozice
  double trimEnd;            // 0.0–1.0 relativní pozice
  Duration? duration;        // délka nahraného zvuku
  List<double>? waveformData; // PCM amplitudy pro vizualizaci

  SampleSlot({required this.index, ...});
}
```

---

## Architektura

```
lib/
├── main.dart
├── app.dart                        # MaterialApp, téma, router
│
├── models/
│   └── sample_slot.dart
│
├── providers/
│   ├── sampler_provider.dart       # List<SampleSlot>, globální stav
│   ├── playback_provider.dart      # just_audio / soloud instance per slot
│   └── recording_provider.dart     # record plugin state machine
│
├── services/
│   ├── audio_engine.dart           # wrapper: init, play, stop, loop, pitch, speed
│   ├── recorder_service.dart       # start/stop nahrávání, temp file management
│   ├── waveform_service.dart       # PCM → List<double> pro painter
│   └── file_service.dart           # kopírování do app documents dir
│
├── screens/
│   ├── main_screen.dart            # Pad grid + transport bar
│   ├── slot_editor_screen.dart     # Bottom sheet / full screen editor
│   └── recording_screen.dart       # Live waveform + record controls
│
├── widgets/
│   ├── pad_grid.dart               # 4×4 grid layout
│   ├── sample_pad.dart             # Jeden pad widget
│   ├── waveform_painter.dart       # CustomPainter pro PCM data
│   ├── pitch_slider.dart           # -12 až +12 st s labelem
│   ├── speed_slider.dart           # 0.25x–2.0x s labelem
│   └── transport_bar.dart          # Play All / Stop / BPM
│
└── theme/
    └── app_theme.dart              # barvy, fonty, tvary
```

---

## UX specifikace

### Main Screen

- **Pad Grid:** 4×4, pady jsou čtvercové, rovnoměrně rozmístěné s mezerami 8px
- **Stavy padu (vizuální):**
  - `empty` — tmavý, bez obsahu, ikona `+`
  - `loaded` — středně osvětlený, zobrazí label nebo `SLOT N`
  - `playing` — pulzující animace (opacity 0.6→1.0, loop), barevný accent
  - `recording` — červené blikání
- **Gesta:**
  - `tap` → přehrát / zastavit
  - `long press` → otevřít Slot Editor
- **Transport Bar** (spodní lišta):
  - `▶ PLAY ALL` — spustí všechny načtené sloty
  - `■ STOP ALL` — zastaví vše
  - `LOOP SPEED` slider — globální override rychlosti (volitelně per-slot)

### Slot Editor (Bottom Sheet)

Otevře se přes `showModalBottomSheet` s `DraggableScrollableSheet`.

**Sekce:**

1. **Header** — název slotu, tlačítko Zavřít
2. **Akce** — `🎤 NAHRÁT` / `📁 IMPORTOVAT`
3. **Waveform Preview** — CustomPainter, zobrazí trim handles
4. **Trim** — Start / End slidery (0.0–1.0)
5. **Pitch** — slider −12 až +12 semitónů, real-time preview
6. **Speed** — slider 0.25×–2.0×
7. **Footer** — `🗑 SMAZAT` / `✓ ULOŽIT`

### Recording Screen

Otevře se jako full-screen route nebo velký bottom sheet.

- Live animovaný waveform (z mic input streamu)
- `● REC` tlačítko (tap = start, tap znovu = stop)
- Max délka nahrávky: 30 sekund (konfigurovatelné)
- Po stopnutí → přejde rovnou do Slot Editoru s waveform preview

---

## Audio Engine — implementační detaily

### Přehrávání s loopem

```dart
// just_audio: loop mode
await player.setLoopMode(LoopMode.one);
await player.setAudioSource(AudioSource.uri(Uri.file(filePath)));
await player.setSpeed(slot.speed);
await player.play();
```

### Pitch shifting

`flutter_soloud` — real-time DSP, podporuje pitch bez změny tempa:

```dart
final soloud = SoLoud.instance;
await soloud.init();
final handle = await soloud.loadFile(filePath);
await soloud.play(handle, loop: true);
soloud.setPitch(handle, semitones: slot.pitch);
soloud.setRelativePlaySpeed(handle, slot.speed);
```

> ⚠️ `just_audio` nemá nativní pitch shift bez změny rychlosti.  
> Pokud `flutter_soloud` způsobí problémy na iOS, fallback: offline pitch shift přes `ffmpeg_kit_flutter`.

### Globální loop speed

Změna globálního slideru → propagace do všech aktivních handlů:
```dart
for (final handle in _activeHandles.values) {
  soloud.setRelativePlaySpeed(handle, globalSpeed * slot.speed);
}
```

---

## Fáze implementace

### Fáze 1 — Kostra (Sprint 1)
- [ ] `flutter create smpl16`
- [ ] Přidat závislosti do `pubspec.yaml`
- [ ] Implementovat `SampleSlot` model + Hive adaptér
- [ ] Riverpod providers (sampler, playback)
- [ ] `MainScreen` s pad gridem (statické, bez audia)
- [ ] `SamplePad` widget se stavy a gesty
- [ ] Základní téma (`app_theme.dart`)

### Fáze 2 — Audio (Sprint 2)
- [ ] Integrace `flutter_soloud` (init, play, stop, loop)
- [ ] Integrace `record` (mic permissions, WAV output)
- [ ] `RecordingScreen` s live animací
- [ ] `AudioEngine` service s clean API
- [ ] Propojení padů s audio engine

### Fáze 3 — Editor (Sprint 3)
- [ ] `SlotEditorScreen` bottom sheet
- [ ] `WaveformPainter` — PCM vizualizace
- [ ] Pitch slider s real-time efektem
- [ ] Speed slider s real-time efektem
- [ ] Trim handles (start/end)
- [ ] Import souboru ze Files.app (`file_picker`)

### Fáze 4 — Polish (Sprint 4)
- [ ] Haptická zpětná vazba na pady
- [ ] Animace přehrávání (pulzování)
- [ ] Transport Bar (Play All / Stop All)
- [ ] Globální Loop Speed slider
- [ ] Persistece slotů přes restart
- [ ] Edge cases: prázdný slot tap, přerušení nahrávání hovorem

---

## pubspec.yaml — klíčové závislosti

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  just_audio: ^0.9.40          # fallback přehrávač (pokud soloud nestačí)
  flutter_soloud: ^2.0.0       # primární audio engine s pitch
  record: ^5.1.0               # nahrávání
  file_picker: ^8.0.0          # import souborů
  permission_handler: ^11.3.0  # mikrofon, storage
  hive_flutter: ^1.1.0         # persistece
  path_provider: ^2.1.0        # cesty k souborům

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  hive_generator: ^2.0.1
```

---

## iOS oprávnění (Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>SMPL-16 potřebuje přístup k mikrofonu pro nahrávání samplů.</string>
<key>NSDocumentsFolderUsageDescription</key>
<string>Import audio souborů pro samply.</string>
```

---

## Estetika / Téma

- **Styl:** Industriální hardware, inspirace MPC/SP-404
- **Barvy:**
  - Background: `#0D0D0D`
  - Pad empty: `#1A1A1A`
  - Pad loaded: `#2A2A2A`
  - Pad playing accent: `#FF6B00` (oranžová)
  - Pad recording: `#FF2222` (červená)
  - Text: `#E0E0E0`
- **Font:** `JetBrains Mono` nebo `IBM Plex Mono` (monospace, technický feel)
- **Tvary:** mírně zaoblené rohy (radius 6), žádné velké kulaté kartičky

---

## Otevřené otázky pro rozhodnutí

1. **Pitch engine:** `flutter_soloud` vs. offline `ffmpeg_kit` — otestovat latenci na fyzickém iPhone
2. **Trim:** real-time vs. offline trim (přegenerovat soubor) — real-time preferováno
3. **Max slotů:** pevně 16, nebo konfigurovatelné?
4. **BPM sync:** v0.1 bez BPM sync, připravit architekturu pro budoucí přidání
5. **Nahrávací formát:** M4A (menší) nebo WAV (bezztrátový) — WAV doporučeno pro DSP

---

*Vygenerováno: Claude Sonnet 4.6 | Projekt: SMPL-16 | v0.1*
