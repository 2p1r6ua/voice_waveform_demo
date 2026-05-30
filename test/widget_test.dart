import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_waveform_demo/main.dart';
import 'package:voice_waveform_demo/voice_waveform/voice_memo_waveform.dart';

void main() {
  testWidgets('voice waveform demo builds and animates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VoiceWaveformDemoApp());

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(VoiceMemoWaveform), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(VoiceMemoWaveform),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(find.text('Status: mock'), findsOneWidget);
    expect(find.text('Use Mock Source'), findsOneWidget);
    expect(find.text('Start Recording'), findsOneWidget);
    expect(find.text('Stop Recording'), findsOneWidget);
    expect(find.text('Clear Waveform'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 160));

    expect(tester.takeException(), isNull);
  });
}
