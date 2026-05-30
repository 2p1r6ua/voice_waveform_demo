# AGENTS.md

## Project

This is a Flutter project for a mobile voice waveform component.

Main target:
- Android first
- iOS later

Current development environment:
- Windows
- Flutter SDK: D:\dev\flutter
- Android SDK: D:\Android\Sdk
- Android device testing first

## Goal

Implement an iPhone Voice Memos style real-time waveform component.

The component should:
- Use Flutter CustomPaint / CustomPainter.
- Display white rounded vertical bars on black background.
- Scroll smoothly from right to left.
- Put the newest bar on the right.
- Map input volume 0.0~1.0 to bar height 12dp~58dp.
- Use 6dp bar gap.
- Use 6dp default bar width.
- Use mock volume stream in phase 1.
- Add real microphone input in phase 2.

## Architecture

Use this directory layout:

lib/
├── main.dart
├── voice_waveform/
│   ├── voice_memo_waveform.dart
│   ├── waveform_controller.dart
│   ├── waveform_painter.dart
│   ├── volume_mapper.dart
│   └── mock_volume_source.dart
└── recorder/
    └── recorder_volume_source.dart

## Development rules

- Do not put all logic in main.dart.
- Keep UI waveform rendering separate from audio recording.
- VoiceMemoWaveform should consume Stream<double>.
- The waveform component should not directly depend on microphone APIs.
- Phase 1 must not add recording dependencies.
- Add real recording only after mock waveform works.
- Prefer small focused changes.
- Run dart format after changes.
- Run flutter analyze before reporting completion.

## Validation commands

Run these commands after implementation:

flutter pub get
dart format lib
flutter analyze
flutter test

If Android device is connected, also run:

flutter run -d android

## Done criteria for phase 1

- App launches on Android.
- Black background is visible.
- White rounded waveform bars are visible.
- Bars scroll smoothly from right to left.
- New bars appear from the right side.
- Bar height stays between 12dp and 58dp.
- Bar gap is 6dp.
- Mock volume has natural voice-like movement instead of pure random jitter.