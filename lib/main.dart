import 'package:flutter/material.dart';

import 'voice_waveform/mock_volume_source.dart';
import 'voice_waveform/voice_memo_waveform.dart';

void main() {
  runApp(const VoiceWaveformDemoApp());
}

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
  late final MockVolumeSource _mockVolumeSource;

  @override
  void initState() {
    super.initState();
    _mockVolumeSource = MockVolumeSource()..start();
  }

  @override
  void dispose() {
    _mockVolumeSource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: VoiceMemoWaveform(volumeStream: _mockVolumeSource.stream),
          ),
        ),
      ),
    );
  }
}
