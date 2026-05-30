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

  test('uses a more sensitive default curve for low volumes', () {
    const mapper = VolumeMapper();

    expect(mapper.mapToHeight(0.25), greaterThan(35));
  });

  test('supports custom min and max heights', () {
    const mapper = VolumeMapper(minHeight: 4, maxHeight: 20);

    expect(mapper.mapToHeight(0), 4);
    expect(mapper.mapToHeight(1), 20);
  });
}
