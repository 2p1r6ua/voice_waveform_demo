import 'package:flutter_test/flutter_test.dart';
import 'package:voice_waveform_demo/voice_waveform/volume_mapper.dart';

void main() {
  test('maps zero volume to the default minimum height', () {
    const mapper = VolumeMapper();

    expect(mapper.mapToHeight(0), 12);
  });

  test('maps full volume to the default maximum height', () {
    const mapper = VolumeMapper();

    expect(mapper.mapToHeight(1), 58);
  });

  test('clamps volume below zero to the default minimum height', () {
    const mapper = VolumeMapper();

    expect(mapper.mapToHeight(-1), 12);
  });

  test('clamps volume above one to the default maximum height', () {
    const mapper = VolumeMapper();

    expect(mapper.mapToHeight(2), 58);
  });

  test('keeps intermediate volume inside the configured height range', () {
    const mapper = VolumeMapper();

    final height = mapper.mapToHeight(0.25);

    expect(height, greaterThan(12));
    expect(height, lessThan(58));
  });

  test('uses a linear default display mapping', () {
    const mapper = VolumeMapper();

    expect(mapper.mapToHeight(0.25), closeTo(23.5, 0.0001));
  });

  test('supports custom min and max heights', () {
    const mapper = VolumeMapper(minHeight: 4, maxHeight: 20);

    expect(mapper.mapToHeight(0), 4);
    expect(mapper.mapToHeight(1), 20);
  });
}
