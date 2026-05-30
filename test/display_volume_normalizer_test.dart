import 'package:flutter_test/flutter_test.dart';
import 'package:voice_waveform_demo/voice_waveform.dart';

void main() {
  test('gates quiet input to silence', () {
    const normalizer = DisplayVolumeNormalizer(noiseGate: 0.10);

    expect(normalizer.normalizeVolume(0.09), 0);
  });

  test('contrast curve lowers small values while preserving peaks', () {
    const normalizer = DisplayVolumeNormalizer(
      noiseGate: 0.10,
      contrastExponent: 1.45,
    );

    expect(normalizer.normalizeVolume(0.25), lessThan(0.15));
    expect(normalizer.normalizeVolume(1), 1);
  });

  test('maps dB using the configured speech display range', () {
    const normalizer = DisplayVolumeNormalizer(floorDb: -45, ceilingDb: -12);

    expect(normalizer.dbToVolume(-45), 0);
    expect(normalizer.dbToVolume(-28.5), closeTo(0.5, 0.0001));
    expect(normalizer.dbToVolume(-12), 1);
  });

  test('clamps invalid and out of range inputs', () {
    const normalizer = DisplayVolumeNormalizer();

    expect(normalizer.normalizeVolume(double.nan), 0);
    expect(normalizer.normalizeVolume(-1), 0);
    expect(normalizer.normalizeVolume(2), 1);
    expect(normalizer.dbToVolume(double.negativeInfinity), 0);
    expect(normalizer.dbToVolume(-90), 0);
    expect(normalizer.dbToVolume(0), 1);
  });
}
