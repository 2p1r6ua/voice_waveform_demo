import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_waveform_demo/main.dart';
import 'package:voice_waveform_demo/recorder/recorder_volume_source.dart';
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

  testWidgets('recording stops when app goes to background', (
    WidgetTester tester,
  ) async {
    final fakeRecorder = _FakeRecordingVolumeSource();

    await tester.pumpWidget(
      VoiceWaveformDemoApp(recorderSourceFactory: () => fakeRecorder),
    );

    await tester.tap(find.text('Start Recording'));
    await tester.pump();

    expect(find.text('Status: recording'), findsOneWidget);
    expect(fakeRecorder.startCount, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(find.text('Status: stopped'), findsOneWidget);
    expect(
      find.text('Recording stopped while app was backgrounded.'),
      findsOneWidget,
    );
    expect(fakeRecorder.stopCount, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Status: stopped'), findsOneWidget);
    expect(fakeRecorder.startCount, 1);
  });
}

class _FakeRecordingVolumeSource implements RecordingVolumeSource {
  final StreamController<double> _controller = StreamController.broadcast();

  int startCount = 0;
  int stopCount = 0;
  int disposeCount = 0;

  @override
  Stream<double> get volumeStream => _controller.stream;

  @override
  Future<void> start() async {
    startCount++;
    _controller.add(0.5);
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _controller.add(0);
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
    await _controller.close();
  }
}
