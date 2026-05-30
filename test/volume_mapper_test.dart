import 'package:flutter_test/flutter_test.dart';
import 'package:voice_waveform_demo/voice_waveform/volume_mapper.dart';

void main() {
  test('maps volume to the configured height range', () {
    const mapper = VolumeMapper();

    expect(mapper.mapToHeight(0), 12);
    expect(mapper.mapToHeight(1), 58);
  });

  test('clamps volume before mapping', () {
    const mapper = VolumeMapper();

    expect(mapper.mapToHeight(-1), 12);
    expect(mapper.mapToHeight(2), 58);
  });

  test('keeps intermediate volume inside the configured height range', () {
    const mapper = VolumeMapper();

    final height = mapper.mapToHeight(0.25);

    expect(height, greaterThan(12));
    expect(height, lessThan(58));
  });
}
