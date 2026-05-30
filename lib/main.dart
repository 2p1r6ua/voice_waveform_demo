import 'dart:async';

import 'package:flutter/material.dart';

import 'recorder/recorder_volume_source.dart';
import 'voice_waveform.dart';

void main() {
  runApp(const VoiceWaveformDemoApp());
}

enum DemoMode { mock, recording, stopped, error }

typedef RecordingVolumeSourceFactory = RecordingVolumeSource Function();

const _demoNoiseGate = 0.14;
const _demoAttack = 0.50;
const _demoMaxRisePerTick = 0.18;

RecordingVolumeSource _defaultRecordingVolumeSourceFactory() {
  return RecorderVolumeSource();
}

class VoiceWaveformDemoApp extends StatelessWidget {
  const VoiceWaveformDemoApp({
    super.key,
    this.recorderSourceFactory = _defaultRecordingVolumeSourceFactory,
  });

  final RecordingVolumeSourceFactory recorderSourceFactory;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Waveform Demo',
      home: VoiceWaveformDemoPage(recorderSourceFactory: recorderSourceFactory),
    );
  }
}

class VoiceWaveformDemoPage extends StatefulWidget {
  const VoiceWaveformDemoPage({
    super.key,
    this.recorderSourceFactory = _defaultRecordingVolumeSourceFactory,
  });

  final RecordingVolumeSourceFactory recorderSourceFactory;

  @override
  State<VoiceWaveformDemoPage> createState() => _VoiceWaveformDemoPageState();
}

class _VoiceWaveformDemoPageState extends State<VoiceWaveformDemoPage>
    with WidgetsBindingObserver {
  MockVolumeSource? _mockVolumeSource;
  late final RecordingVolumeSource _recorderVolumeSource;
  late Stream<double> _activeVolumeStream;
  final VoiceMemoWaveformController _waveformController =
      VoiceMemoWaveformController();

  DemoMode _mode = DemoMode.mock;
  String? _errorMessage;
  int _recordingRequestId = 0;
  bool _isStartInProgress = false;
  bool _isStopInProgress = false;
  bool _showDebugInfo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recorderVolumeSource = widget.recorderSourceFactory();
    _startMockSource();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_mockVolumeSource?.dispose());
    unawaited(_recorderVolumeSource.dispose());
    _waveformController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_mode == DemoMode.recording) {
          unawaited(_stopRecordingForLifecycle());
        }
      case AppLifecycleState.resumed:
        break;
    }
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
                volumeStream: _activeVolumeStream,
                controller: _waveformController,
                noiseGate: _demoNoiseGate,
                attack: _demoAttack,
                maxRisePerTick: _demoMaxRisePerTick,
              ),
              if (_showDebugInfo) ...[
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _waveformController,
                  builder: (context, _) {
                    return _DebugInfo(
                      mode: _mode,
                      rawVolume: _waveformController.lastRawVolume,
                      normalizedVolume:
                          _waveformController.lastNormalizedVolume,
                      displayVolume: _waveformController.lastDisplayVolume,
                      smoothedVolume: _waveformController.lastSmoothedVolume,
                      estimatedBarHeight:
                          _waveformController.lastEstimatedBarHeight,
                      impulseSuppressed:
                          _waveformController.lastImpulseSuppressed,
                    );
                  },
                ),
              ],
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
                  _DemoButton(
                    label: _showDebugInfo ? 'Hide Debug' : 'Show Debug',
                    onPressed: _toggleDebugInfo,
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
    _recordingRequestId++;
    await _recorderVolumeSource.stop();
    await _mockVolumeSource?.dispose();
    _startMockSource();
    if (!mounted) {
      return;
    }

    setState(() {
      _mode = DemoMode.mock;
      _errorMessage = null;
      _waveformController.clear();
    });
  }

  Future<void> _startRecording() async {
    if (_mode == DemoMode.recording || _isStartInProgress) {
      return;
    }

    _isStartInProgress = true;
    final requestId = ++_recordingRequestId;
    await _mockVolumeSource?.dispose();
    _mockVolumeSource = null;

    if (mounted) {
      setState(() {
        _activeVolumeStream = _recorderVolumeSource.volumeStream;
        _errorMessage = null;
        _waveformController.clear();
      });
    }

    try {
      await _recorderVolumeSource.start();
      if (!mounted || requestId != _recordingRequestId) {
        return;
      }
      setState(() {
        _mode = DemoMode.recording;
        _errorMessage = null;
      });
    } on RecorderPermissionDeniedException {
      if (requestId == _recordingRequestId) {
        _showRecordingError('Microphone permission was denied.');
      }
    } on RecorderPermissionPermanentlyDeniedException {
      if (requestId == _recordingRequestId) {
        _showRecordingError(
          'Microphone permission is permanently denied. Enable it in Android app settings.',
        );
      }
    } on RecorderStartException catch (error) {
      if (requestId == _recordingRequestId) {
        _showRecordingError(error.toString());
      }
    } catch (error) {
      if (requestId == _recordingRequestId) {
        _showRecordingError('Recording failed: $error');
      }
    } finally {
      _isStartInProgress = false;
    }
  }

  Future<void> _stopRecording() async {
    _recordingRequestId++;
    if (_isStopInProgress) {
      return;
    }

    _isStopInProgress = true;
    try {
      await _recorderVolumeSource.stop();
    } finally {
      _isStopInProgress = false;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _mode = DemoMode.stopped;
      _errorMessage = null;
    });
  }

  void _clearWaveform() {
    _waveformController.clear();
  }

  void _toggleDebugInfo() {
    setState(() {
      _showDebugInfo = !_showDebugInfo;
    });
  }

  Future<void> _stopRecordingForLifecycle() async {
    _recordingRequestId++;
    if (_isStopInProgress) {
      return;
    }

    _isStopInProgress = true;
    try {
      await _recorderVolumeSource.stop();
    } finally {
      _isStopInProgress = false;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _mode = DemoMode.stopped;
      _errorMessage = 'Recording stopped while app was backgrounded.';
    });
  }

  void _showRecordingError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _mode = DemoMode.error;
      _errorMessage = message;
    });
  }
}

class _DebugInfo extends StatelessWidget {
  const _DebugInfo({
    required this.mode,
    required this.rawVolume,
    required this.normalizedVolume,
    required this.displayVolume,
    required this.smoothedVolume,
    required this.estimatedBarHeight,
    required this.impulseSuppressed,
  });

  final DemoMode mode;
  final double rawVolume;
  final double normalizedVolume;
  final double displayVolume;
  final double smoothedVolume;
  final double estimatedBarHeight;
  final bool impulseSuppressed;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Debug: mode=${mode.name}  '
      'raw=${rawVolume.toStringAsFixed(3)}  '
      'normalized=${normalizedVolume.toStringAsFixed(3)}\n'
      'display=${displayVolume.toStringAsFixed(3)}  '
      'smoothed=${smoothedVolume.toStringAsFixed(3)}  '
      'height=${estimatedBarHeight.toStringAsFixed(1)}dp\n'
      'impulse=$impulseSuppressed  '
      'noiseGate=$_demoNoiseGate  '
      'attack=$_demoAttack  '
      'maxRise=$_demoMaxRisePerTick',
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white54, fontSize: 12),
    );
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
