import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_waveform_demo/voice_waveform/display_volume_normalizer.dart';
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
      maxRisePerTick: 1,
      medianWindow: 1,
      impulseSuppressionEnabled: false,
      displayVolumeNormalizer: const DisplayVolumeNormalizer(
        noiseGate: 0,
        contrastExponent: 1,
      ),
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

  test('supports pause resume and clear through public controller', () async {
    final streamController = StreamController<double>();
    final publicController = VoiceMemoWaveformController();
    final waveformController = WaveformController(
      volumeStream: streamController.stream,
      publicController: publicController,
    )..start();

    streamController.add(0.5);
    await Future<void>.delayed(Duration.zero);
    expect(waveformController.sampleCount, 1);

    publicController.pause();
    streamController.add(0.8);
    await Future<void>.delayed(Duration.zero);
    expect(publicController.isPaused, isTrue);
    expect(waveformController.sampleCount, 1);

    publicController.resume();
    streamController.add(0.8);
    await Future<void>.delayed(Duration.zero);
    expect(publicController.isPaused, isFalse);
    expect(waveformController.sampleCount, 2);

    publicController.clear();
    streamController.add(0.3);
    await Future<void>.delayed(Duration.zero);
    expect(waveformController.sampleCount, 1);

    await streamController.close();
    waveformController.dispose();
    publicController.dispose();
  });

  test(
    'suppresses a single-frame spike before it reaches full height',
    () async {
      final streamController = StreamController<double>();
      final publicController = VoiceMemoWaveformController();
      final waveformController = WaveformController(
        volumeStream: streamController.stream,
        publicController: publicController,
      )..start();

      streamController.add(1);
      await Future<void>.delayed(Duration.zero);

      expect(waveformController.volumeAt(0), lessThan(0.25));
      expect(publicController.lastImpulseSuppressed, isTrue);

      await streamController.close();
      waveformController.dispose();
      publicController.dispose();
    },
  );

  test('allows sustained high input to climb over multiple samples', () async {
    final streamController = StreamController<double>();
    final waveformController = WaveformController(
      volumeStream: streamController.stream,
    )..start();

    for (var index = 0; index < 4; index++) {
      streamController.add(1);
    }
    await Future<void>.delayed(Duration.zero);

    expect(
      waveformController.volumeAt(3),
      greaterThan(waveformController.volumeAt(0)),
    );
    expect(waveformController.volumeAt(3), lessThan(1));

    await streamController.close();
    waveformController.dispose();
  });

  test(
    'limits only rising values and lets release handle falling values',
    () async {
      final streamController = StreamController<double>();
      final waveformController = WaveformController(
        volumeStream: streamController.stream,
        attack: 1,
        release: 0.5,
        maxRisePerTick: 0.2,
        medianWindow: 1,
        impulseSuppressionEnabled: false,
        displayVolumeNormalizer: const DisplayVolumeNormalizer(
          noiseGate: 0,
          contrastExponent: 1,
        ),
      )..start();

      streamController.add(0.8);
      streamController.add(0);
      await Future<void>.delayed(Duration.zero);

      expect(waveformController.volumeAt(0), closeTo(0.2, 0.0001));
      expect(waveformController.volumeAt(1), closeTo(0.1, 0.0001));

      await streamController.close();
      waveformController.dispose();
    },
  );
}
