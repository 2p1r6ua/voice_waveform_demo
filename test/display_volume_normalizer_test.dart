import 'package:flutter_test/flutter_test.dart';
import 'package:voice_waveform_demo/voice_waveform.dart';

void main() {
  test('gates quiet input to silence', () {
    const normalizer = DisplayVolumeNormalizer();

    expect(normalizer.normalizeVolume(0.13), 0);
  });

  test('contrast curve lowers small values while preserving peaks', () {
    const normalizer = DisplayVolumeNormalizer();

    expect(normalizer.normalizeVolume(0.35), lessThan(0.15));
    expect(normalizer.normalizeVolume(1), 1);
  });

  test('maps dB using the configured speech display range', () {
    const normalizer = DisplayVolumeNormalizer();

    expect(normalizer.dbToVolume(-45), 0);
    expect(normalizer.dbToVolume(-26.5), closeTo(0.5, 0.0001));
    expect(normalizer.dbToVolume(-8), 1);
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
