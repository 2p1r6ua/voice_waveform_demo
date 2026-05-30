import 'dart:async';

import 'package:flutter/material.dart';

import 'recorder/recorder_volume_source.dart';
import 'voice_waveform/mock_volume_source.dart';
import 'voice_waveform/voice_memo_waveform.dart';

void main() {
  runApp(const VoiceWaveformDemoApp());
}

enum DemoMode { mock, recording, stopped, error }

class VoiceWaveformDemoApp extends StatelessWidget {
  const VoiceWaveformDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Waveform Demo',
      home: VoiceWaveformDemoPage(),
    );
  }
}

class VoiceWaveformDemoPage extends StatefulWidget {
  const VoiceWaveformDemoPage({super.key});

  @override
  State<VoiceWaveformDemoPage> createState() => _VoiceWaveformDemoPageState();
}

class _VoiceWaveformDemoPageState extends State<VoiceWaveformDemoPage> {
  MockVolumeSource? _mockVolumeSource;
  late final RecorderVolumeSource _recorderVolumeSource;
  late Stream<double> _activeVolumeStream;

  DemoMode _mode = DemoMode.mock;
  String? _errorMessage;
  int _waveformGeneration = 0;

  @override
  void initState() {
    super.initState();
    _recorderVolumeSource = RecorderVolumeSource();
    _startMockSource();
  }

  @override
  void dispose() {
    unawaited(_mockVolumeSource?.dispose());
    unawaited(_recorderVolumeSource.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Status: ${_mode.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (_errorMessage case final message?) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
              const SizedBox(height: 32),
              VoiceMemoWaveform(
                key: ValueKey<int>(_waveformGeneration),
                volumeStream: _activeVolumeStream,
              ),
              const SizedBox(height: 36),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DemoButton(
                    label: 'Use Mock Source',
                    onPressed: _useMockSource,
                  ),
                  _DemoButton(
                    label: 'Start Recording',
                    onPressed: _startRecording,
                  ),
                  _DemoButton(
                    label: 'Stop Recording',
                    onPressed: _stopRecording,
                  ),
                  _DemoButton(
                    label: 'Clear Waveform',
                    onPressed: _clearWaveform,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startMockSource() {
    _mockVolumeSource = MockVolumeSource()..start();
    _activeVolumeStream = _mockVolumeSource!.stream;
  }

  Future<void> _useMockSource() async {
    await _recorderVolumeSource.stop();
    await _mockVolumeSource?.dispose();
    _startMockSource();
    setState(() {
      _mode = DemoMode.mock;
      _errorMessage = null;
      _waveformGeneration++;
    });
  }

  Future<void> _startRecording() async {
    if (_mode == DemoMode.recording) {
      return;
    }

    await _mockVolumeSource?.dispose();
    _mockVolumeSource = null;

    setState(() {
      _activeVolumeStream = _recorderVolumeSource.volumeStream;
      _errorMessage = null;
      _waveformGeneration++;
    });

    try {
      await _recorderVolumeSource.start();
      setState(() => _mode = DemoMode.recording);
    } on RecorderPermissionException {
      setState(() {
        _mode = DemoMode.error;
        _errorMessage = 'Microphone permission was not granted.';
      });
    } catch (error) {
      setState(() {
        _mode = DemoMode.error;
        _errorMessage = 'Recording failed: $error';
      });
    }
  }

  Future<void> _stopRecording() async {
    await _recorderVolumeSource.stop();
    if (!mounted) {
      return;
    }

    setState(() {
      _mode = DemoMode.stopped;
      _errorMessage = null;
    });
  }

  void _clearWaveform() {
    setState(() => _waveformGeneration++);
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}
