# Voice Memo Waveform Spec

## Visual Style

Reference: iPhone Voice Memos recording waveform.

- Background: black
- Bar color: white
- Bar shape: rounded vertical rectangle
- Bar alignment: vertically centered
- Min bar height: 12dp
- Max bar height: 58dp
- Bar gap: 6dp
- Default bar width: 6dp
- Scroll direction: right to left
- Newest data: right side
- Older data: moves left

## Data Input

Phase 1:

VoiceMemoWaveform receives:

Stream<double> volumeStream

The volume value range is:

0.0 ~ 1.0

Phase 2:

RecorderVolumeSource will provide the same Stream<double> from real microphone data.

## Volume Mapping

Input volume should be clamped:

0.0 <= volume <= 1.0

Use a curve to improve low-volume visibility:

curved = pow(volume, 0.6)

Map to height:

height = 12.0 + curved * (58.0 - 12.0)

## Animation

Use 60fps-level animation with AnimationController or Ticker.

Do not only repaint when new volume data arrives.

The component should scroll continuously.

Suggested bar interval:

80ms

Suggested pitch:

barWidth + barGap = 12dp

Suggested scroll speed:

12dp / 80ms = 150dp/s

## Phase 1

Implement mock waveform only.

Files:
- lib/voice_waveform/voice_memo_waveform.dart
- lib/voice_waveform/waveform_controller.dart
- lib/voice_waveform/waveform_painter.dart
- lib/voice_waveform/volume_mapper.dart
- lib/voice_waveform/mock_volume_source.dart
- lib/main.dart

## Phase 2

Add real microphone input.

Possible packages:
- record
- permission_handler

Android permission:

<uses-permission android:name="android.permission.RECORD_AUDIO" />

iOS permission later:

NSMicrophoneUsageDescription