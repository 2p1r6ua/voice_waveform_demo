import 'package:flutter_test/flutter_test.dart';
import 'package:voice_waveform_demo/recorder/recorder_volume_source.dart';

void main() {
  test('maps dBFS amplitude into normalized volume', () {
    expect(dbToNormalizedVolume(-60), 0);
    expect(dbToNormalizedVolume(-30), 0.5);
    expect(dbToNormalizedVolume(0), 1);
  });

  test('clamps dBFS amplitude outside the expected range', () {
    expect(dbToNormalizedVolume(-90), 0);
    expect(dbToNormalizedVolume(12), 1);
    expect(dbToNormalizedVolume(double.negativeInfinity), 0);
  });

  test('smooths recorder volume with faster attack than release', () {
    final attacked = smoothRecorderVolume(
      previous: 0,
      current: 1,
      attack: 0.72,
      release: 0.22,
    );
    final released = smoothRecorderVolume(
      previous: attacked,
      current: 0,
      attack: 0.72,
      release: 0.22,
    );

    expect(attacked, closeTo(0.72, 0.0001));
    expect(released, closeTo(0.5616, 0.0001));
  });
}
