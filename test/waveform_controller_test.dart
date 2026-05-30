import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_waveform_demo/voice_waveform/waveform_controller.dart';

void main() {
  test('keeps only the configured number of visible samples', () async {
    final streamController = StreamController<double>();
    final waveformController = WaveformController(
      volumeStream: streamController.stream,
      maxVisibleSamples: 3,
    )..start();

    for (var index = 0; index < 5; index++) {
      streamController.add(0.5);
    }
    await Future<void>.delayed(Duration.zero);

    expect(waveformController.sampleCount, 3);

    await streamController.close();
    waveformController.dispose();
  });

  test('attacks faster than it releases', () async {
    final streamController = StreamController<double>();
    final waveformController = WaveformController(
      volumeStream: streamController.stream,
      attack: 0.7,
      release: 0.2,
    )..start();

    streamController.add(0);
    streamController.add(1);
    streamController.add(0);
    await Future<void>.delayed(Duration.zero);

    expect(waveformController.volumeAt(1), closeTo(0.7, 0.0001));
    expect(waveformController.volumeAt(2), closeTo(0.56, 0.0001));

    await streamController.close();
    waveformController.dispose();
  });
}
