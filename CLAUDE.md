# Sample16 — CLAUDE.md

## Overview

Flutter 16-slot mobile sampler app (`smpl16`). Load audio samples into 16 pads, trigger them with touch, adjust per-pad settings.

Flutter app lives in `smpl16/` subdirectory.

## Commands

```bash
cd smpl16
flutter pub get
flutter run -d ios
flutter run -d android
flutter build ios
flutter build apk
flutter analyze
```

## Structure

```
smpl16/lib/
├── main.dart
├── app.dart                 # App root
├── models/                  # Sample, pad state models
├── providers/               # State management
├── screens/                 # Main pad grid screen, settings
├── services/                # Audio engine (just_audio or similar)
├── theme/                   # Visual theme
└── widgets/                 # Pad widget, waveform display
```

## Notes

- Prototype reference material in `prototype/`
- 16 pads arranged in grid, each mapped to a sample file
- Audio: low-latency playback via platform audio API
