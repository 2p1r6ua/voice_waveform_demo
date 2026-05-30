# Phase 5.5: Waveform Dynamic Range Calibration

## Goal

The current waveform is functional, but the height difference between bars is not visually obvious enough.

The goal of Phase 5.5 is to improve the visual dynamic range of the waveform so that it looks closer to the iPhone Voice Memos reference:

* Quiet audio should stay close to the minimum bar height.
* Normal speech should produce visible height changes.
* Louder speech should create clear tall peaks.
* The waveform should not look like a row of nearly equal-height bars.
* The existing reusable component API should remain stable.

## Current Problem

Observed issue:

```text
Most bars are visually similar in height.
Low-volume and high-volume segments are not separated clearly.
The waveform does not show enough peak/valley contrast.
```

Likely causes:

```text
1. The previous curve `pow(volume, 0.6)` boosts low volume values and compresses visual contrast.
2. Fixed dB mapping such as -60dB~0dB may not match the actual microphone range.
3. Release smoothing may be too strong, causing bars to remain high for too long.
4. Background noise is mapped to visible medium-height bars instead of staying near the minimum height.
```

## Required Improvements

### 1. Add display-oriented volume normalization

Introduce a separate display normalization layer.

Suggested file:

```text
lib/voice_waveform/display_volume_normalizer.dart
```

This layer should convert raw recorder volume or dB into display volume:

```text
raw audio level -> normalized 0.0~1.0 -> display volume 0.0~1.0 -> bar height
```

The waveform painter should still only receive final bar heights or normalized display values.

### 2. Use adaptive dB range for real microphone

Instead of always using:

```text
-60dB ~ 0dB
```

support a more practical display range such as:

```text
noise floor: ambientDb + 6dB
ceiling: rolling high level, or around -8dB to -12dB
```

Recommended mapping:

```text
normalized = ((db - floorDb) / (ceilingDb - floorDb)).clamp(0.0, 1.0)
```

Suggested defaults:

```text
floorDb = -45.0
ceilingDb = -12.0
```

Allow adaptive calibration based on recent values.

### 3. Add noise gate

If the normalized value is very low, keep it near the minimum bar height.

Suggested logic:

```text
if normalized < noiseGate:
    displayVolume = 0.0
else:
    displayVolume = (normalized - noiseGate) / (1.0 - noiseGate)
```

Suggested default:

```text
noiseGate = 0.08 ~ 0.15
```

### 4. Use contrast curve

To make height differences more obvious, use an exponent greater than 1.0.

Suggested:

```text
displayVolume = pow(displayVolume, contrastExponent)
```

Suggested default:

```text
contrastExponent = 1.45
```

Tuning range:

```text
1.2 ~ 1.8
```

Do not use `pow(volume, 0.6)` as the default for the final display, because it makes quiet bars too tall and reduces visual contrast.

### 5. Tune smoothing

Use attack/release smoothing but avoid excessive release.

Suggested:

```text
if newValue > previousValue:
    smoothed = previousValue + (newValue - previousValue) * attack
else:
    smoothed = previousValue + (newValue - previousValue) * release
```

Suggested defaults:

```text
attack = 0.75
release = 0.22
```

If the waveform still looks too flat, reduce release or apply smoothing before the contrast curve instead of after it.

### 6. Debug overlay

Add an optional debug mode for the demo page.

When enabled, show:

```text
rawDb
normalizedVolume
displayVolume
barHeight
mode: mock / recording
```

This is only for tuning and should be optional.

## Acceptance Criteria

Phase 5.5 is complete when:

```text
1. Quiet environment produces mostly short bars near 12dp.
2. Speaking produces clearly visible height variation.
3. Louder speech creates tall peaks close to 58dp.
4. The waveform does not look like a uniform equal-height strip.
5. Mock mode still works.
6. Recording mode still works.
7. Existing reusable component API is not broken.
8. flutter analyze passes.
9. flutter test passes.
```

## Validation Commands

```powershell
dart format lib test
flutter analyze
flutter test
flutter run -d android
```
