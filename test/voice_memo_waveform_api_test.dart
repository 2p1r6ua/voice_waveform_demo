import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_waveform_demo/voice_waveform.dart';

void main() {
  testWidgets('builds with only a volume stream', (WidgetTester tester) async {
    final streamController = StreamController<double>();

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceMemoWaveform(volumeStream: streamController.stream),
      ),
    );

    expect(find.byType(VoiceMemoWaveform), findsOneWidget);

    await streamController.close();
  });

  testWidgets('accepts reusable visual and timing parameters', (
    WidgetTester tester,
  ) async {
    final streamController = StreamController<double>();
    final controller = VoiceMemoWaveformController();

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceMemoWaveform(
          volumeStream: streamController.stream,
          controller: controller,
          minBarHeight: 10,
          maxBarHeight: 40,
          barWidth: 4,
          barGap: 8,
          barColor: Colors.green,
          backgroundColor: Colors.blue,
          barInterval: const Duration(milliseconds: 120),
          contrastExponent: 1.6,
          noiseGate: 0.12,
          attack: 0.8,
          release: 0.18,
          maxRisePerTick: 0.22,
          medianWindow: 3,
          impulseSuppressionEnabled: true,
          impulseThreshold: 0.5,
          impulseDamping: 0.4,
          sustainFrames: 2,
        ),
      ),
    );

    expect(find.byType(VoiceMemoWaveform), findsOneWidget);
    controller.pause();
    expect(controller.isPaused, isTrue);
    controller.resume();
    expect(controller.isPaused, isFalse);
    controller.clear();

    await streamController.close();
    controller.dispose();
  });
}
