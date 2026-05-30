# AGENTS.md 

## Platform Scope

This project is Android-first and Android-only for the current development cycle.

Do not implement iOS-specific files, permissions, Podfile changes, or Xcode settings unless explicitly requested later.

Current scope:

* Android physical device testing
* Flutter UI component
* Android microphone permission
* Android recording source
* Reusable Flutter widget API

Out of scope for now:

* iOS support
* Web support
* Windows desktop support
* Publishing to pub.dev

## Development Phases

### Phase 1: Mock Waveform UI

Status: implemented or in progress.

Goal:

* Implement the waveform UI with mock volume data.
* No microphone dependency.
* No recording packages.

### Phase 2: Visual Refinement

Goal:

* Tune the waveform to look closer to iPhone Voice Memos.
* Improve smoothness, spacing, height behavior, and natural voice-like movement.
* Preserve the existing public API.

Rules:

* Do not add microphone dependencies.
* Do not rewrite the whole component.
* Only improve rendering, animation, and mock source behavior.
* Keep `VoiceMemoWaveform` consuming `Stream<double>`.

### Phase 3: Android Recording Input

Goal:

* Add Android microphone recording as a volume source.
* Keep UI rendering independent from recording logic.

Allowed packages:

* `record`
* `permission_handler`

Rules:

* Add Android microphone permission.
* Do not modify the waveform rendering logic unnecessarily.
* The recorder should only output `Stream<double>`.
* Keep mock mode working.

### Phase 4: Permission and Lifecycle

Goal:

* Make the Android recording flow robust.

Handle:

* Permission denied
* Permission permanently denied
* Start recording
* Stop recording
* App background / foreground
* Widget dispose
* Multiple start/stop calls
* Recorder initialization failure

Rules:

* No crashes on repeated button clicks.
* No stream leak after dispose.
* No recording left running after leaving the page.

### Phase 5: Reusable Component API

Goal:

* Make the waveform component reusable in other Flutter pages.

Expected public API:

* `VoiceMemoWaveform`
* `VoiceMemoWaveformController` if needed
* `MockVolumeSource`
* `RecorderVolumeSource`

The component should support:

* Custom min/max bar height
* Custom bar width
* Custom bar gap
* Custom bar color
* Custom background color
* Custom bar interval
* Pause / resume / clear if useful

### Phase 6: Testing and Documentation

Goal:

* Add basic tests and usage docs.

Expected outputs:

* README usage example
* Android permission notes
* Troubleshooting notes
* Basic widget test or unit tests for volume mapping
* `flutter analyze` clean
* `flutter test` pass

## Validation Commands

Run these after every phase:

```powershell
dart format lib test
flutter analyze
flutter test
```

For Android device testing:

```powershell
flutter devices
flutter run -d android
```

If Gradle or Android SDK fails because of network, check:

* Gradle proxy
* Android Studio proxy
* NDK installation
* `D:\Android\Sdk`
* `C:\Users\hello\.gradle\gradle.properties`

## Coding Rules

* Prefer small focused changes.
* Do not rewrite working code unless necessary.
* Keep UI, data mapping, mock data, and recording source separated.
* Do not put business logic into `main.dart`.
* Do not add iOS-specific implementation.
* Preserve mock mode when adding real recording mode.
* If a package API is uncertain, inspect the installed package or generated documentation before coding.
* Always explain changed files after implementation.
