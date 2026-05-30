# SPEC.md 

## Android-only Current Scope

This project currently targets Android only.

The final component should run on:

* Android physical device
* Flutter debug mode
* Flutter profile mode

iOS support is intentionally excluded for now.

## Visual Refinement Requirements

The waveform should resemble iPhone Voice Memos:

* Black background
* White rounded bars
* Bars vertically centered
* New bars appear on the right
* Old bars move smoothly to the left
* No visible jumping when new bars are added
* No sharp height flicker
* Quiet audio still shows minimum bars
* Loud audio should not clip too aggressively

Default parameters:

```text
minBarHeight = 12dp
maxBarHeight = 58dp
barGap = 6dp
barWidth = 6dp
barInterval = 80ms
scrollDirection = rightToLeft
```

## Volume Mapping

Input volume range:

```text
0.0 ~ 1.0
```

Recommended mapping:

```text
clamped = clamp(volume, 0.0, 1.0)
curved = pow(clamped, 0.6)
height = minBarHeight + curved * (maxBarHeight - minBarHeight)
```

Recommended smoothing:

```text
if newVolume > previousVolume:
    use faster attack
else:
    use slower release
```

Suggested coefficients:

```text
attack = 0.55 ~ 0.75
release = 0.15 ~ 0.35
```

## Android Recording Requirements

The recording module should provide:

```dart
abstract class VolumeSource {
  Stream<double> get volumeStream;
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}
```

The UI component should not know whether the volume comes from:

* mock data
* Android microphone
* file playback
* network stream

## Android Permission

Add to:

```text
android/app/src/main/AndroidManifest.xml
```

Required permission:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

The app must handle:

* permission granted
* permission denied
* permission permanently denied
* unavailable microphone

## Demo Page Requirements

The demo page should include:

```text
Use Mock Source
Start Recording
Stop Recording
Clear Waveform
```

The demo should show:

* current mode: mock / recording / stopped
* permission state if available
* simple error message if recording fails

## Performance Requirements

Target:

* Smooth 60fps-level animation on Android
* No unbounded list growth
* No stream leak
* No timer leak
* No unnecessary object allocation inside painter loop

The waveform should store only enough bars for the visible screen plus a small buffer.

---
