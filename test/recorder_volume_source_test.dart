import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_waveform_demo/recorder/recorder_volume_source.dart';

void main() {
  test('maps dBFS amplitude into normalized volume', () {
    expect(dbToNormalizedVolume(-45), 0);
    expect(dbToNormalizedVolume(-26.5), 0.5);
    expect(dbToNormalizedVolume(-8), 1);
  });

  test('clamps dBFS amplitude outside the expected range', () {
    expect(dbToNormalizedVolume(-90), 0);
    expect(dbToNormalizedVolume(12), 1);
    expect(dbToNormalizedVolume(double.negativeInfinity), 0);
  });

  test('smooths recorder volume with faster attack than release', () {
    final attacked = smoothRecorderVolume(previous: 0, current: 1);
    final released = smoothRecorderVolume(previous: attacked, current: 0);

    expect(attacked, closeTo(0.5, 0.0001));
    expect(released, closeTo(0.41, 0.0001));
  });

  test('maps microphone permission statuses', () {
    expect(
      microphonePermissionResultFromStatus(PermissionStatus.granted),
      MicrophonePermissionResult.granted,
    );
    expect(
      microphonePermissionResultFromStatus(PermissionStatus.denied),
      MicrophonePermissionResult.denied,
    );
    expect(
      microphonePermissionResultFromStatus(PermissionStatus.permanentlyDenied),
      MicrophonePermissionResult.permanentlyDenied,
    );
  });
}
