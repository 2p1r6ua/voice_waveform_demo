# Voice Waveform Demo

Flutter demo and reusable Android-first voice waveform component inspired by
iPhone Voice Memos. The waveform is drawn with `CustomPaint` and consumes a
plain `Stream<double>` where each volume sample is in the `0.0` to `1.0` range.

## Project Goal

- Render white rounded vertical bars on a black background.
- Scroll smoothly from right to left with the newest bar entering on the right.
- Keep default bar height between `12dp` and `58dp`.
- Keep default bar width and gap at `6dp`.
- Support both mock volume input and Android microphone input.
- Keep waveform rendering independent from recording and permission logic.

Current scope is Android only. iOS, Web, Windows desktop, and publishing are out
of scope for this development cycle.

## Android Environment

Expected local setup:

- Windows development machine
- Flutter SDK: `D:\dev\flutter`
- Android SDK: `D:\Android\Sdk`
- Android physical device testing first
- Test device used during development: `DBY W09`, Android 12

Useful checks:

```powershell
D:\dev\flutter\bin\flutter.bat doctor -v
D:\dev\flutter\bin\flutter.bat devices
adb devices
```

If `flutter` or `dart` is not on `PATH`, call the tools through
`D:\dev\flutter\bin\flutter.bat` or
`D:\dev\flutter\bin\cache\dart-sdk\bin\dart.exe`.

## Run Commands

Install or refresh dependencies:

```powershell
D:\dev\flutter\bin\flutter.bat pub get
```

Run static analysis and tests:

```powershell
D:\dev\flutter\bin\cache\dart-sdk\bin\dart.exe format lib test
D:\dev\flutter\bin\flutter.bat analyze
D:\dev\flutter\bin\flutter.bat test
```

Run on an Android device:

```powershell
D:\dev\flutter\bin\flutter.bat devices
D:\dev\flutter\bin\flutter.bat run -d android
```

If the `android` selector is not accepted by the installed Flutter version, use
the concrete device id shown by `flutter devices`, for example:

```powershell
D:\dev\flutter\bin\flutter.bat run -d 8UTBB22125200669
```

## Demo Modes

The demo page includes:

- `Use Mock Source`
- `Start Recording`
- `Stop Recording`
- `Clear Waveform`
- `Show Debug` / `Hide Debug`

### Mock Mode

Mock mode uses `MockVolumeSource`, which emits natural voice-like volume values
without opening the microphone. Use this mode to verify the waveform UI,
scrolling, smoothing, and visual tuning without Android permission prompts.

### Recording Mode

Recording mode uses `RecorderVolumeSource`, which wraps the Android microphone
through the `record` package and emits normalized volume samples. The waveform
still only receives a `Stream<double>`; it does not depend on microphone APIs.

The recording chain includes dB normalization, display dynamic range tuning,
noise gating, median filtering, max-rise limiting, attack/release smoothing, and
light impulse suppression for short taps or device bumps.

## Reusable Component Usage

Minimal usage:

```dart
VoiceMemoWaveform(volumeStream: someVolumeStream)
```

Optional controller:

```dart
final controller = VoiceMemoWaveformController();

VoiceMemoWaveform(
  volumeStream: someVolumeStream,
  controller: controller,
);

controller.pause();
controller.resume();
controller.clear();
```

Common visual and sensitivity parameters:

```dart
VoiceMemoWaveform(
  volumeStream: someVolumeStream,
  minBarHeight: 12,
  maxBarHeight: 58,
  barWidth: 6,
  barGap: 6,
  noiseGate: 0.16,
  contrastExponent: 1.55,
  attack: 0.50,
  release: 0.18,
  maxRisePerTick: 0.18,
)
```

## Android Permission

Microphone recording requires this permission in
`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

The demo handles:

- permission granted
- permission denied
- permission permanently denied
- repeated start/stop taps
- app backgrounding during recording

If permission is permanently denied, enable microphone permission again from
Android app settings.

## Troubleshooting

### The waveform moves in mock mode but not recording mode

- Confirm microphone permission was granted.
- Tap `Show Debug` and check whether display volume changes while speaking.
- Speak close to the device microphone.
- Check that the device is not using a blocked or unavailable input.

### Quiet room still shows tall bars

- Increase `noiseGate`.
- Increase `contrastExponent`.
- Raise `ceilingDb` in `RecorderVolumeSource`.

### Speech looks too small

- Lower `noiseGate`.
- Increase `attack`.
- Lower `ceilingDb` toward `-10.0` or `-12.0`.

### Taps or device bumps make large spikes

- Lower `maxRisePerTick`.
- Lower `impulseDamping`.
- Increase `impulseThreshold`.

### Gradle or Android SDK issues

- Check `D:\Android\Sdk`.
- Check the Android Studio SDK Manager.
- If downloads fail, check proxy settings in
  `C:\Users\hello\.gradle\gradle.properties`.
- If NDK installation is corrupted, delete the corrupted NDK folder and
  reinstall it from Android Studio SDK Manager.

## Known Limits

- Current implementation is Android-only.
- No iOS, Web, Windows desktop, or publishing support is implemented.
- The waveform is a visual volume display, not speech recognition or a full
  audio analysis tool.
- Impulse suppression is lightweight and heuristic; extremely loud or sustained
  non-speech sounds may still produce visible bars.
