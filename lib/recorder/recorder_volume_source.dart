import 'dart:async';
import 'dart:io';

import 'package:record/record.dart';

class RecorderPermissionException implements Exception {
  const RecorderPermissionException();

  @override
  String toString() => 'Microphone permission was not granted.';
}

class RecorderVolumeSource {
  RecorderVolumeSource({
    AudioRecorder? recorder,
    this.amplitudeInterval = const Duration(milliseconds: 80),
    this.attack = 0.72,
    this.release = 0.22,
  }) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final Duration amplitudeInterval;
  final double attack;
  final double release;

  final StreamController<double> _volumeController =
      StreamController<double>.broadcast();

  StreamSubscription<Amplitude>? _amplitudeSubscription;
  File? _recordingFile;
  double _smoothedVolume = 0;
  bool _isRecording = false;
  bool _isStarting = false;
  bool _isDisposed = false;

  Stream<double> get volumeStream => _volumeController.stream;

  Future<void> start() async {
    if (_isDisposed || _isRecording || _isStarting) {
      return;
    }

    _isStarting = true;
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw const RecorderPermissionException();
      }

      _smoothedVolume = 0;
      _recordingFile = await _createRecordingFile();
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(amplitudeInterval)
          .listen(_handleAmplitude, onError: _volumeController.addError);

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
        path: _recordingFile!.path,
      );
      _isRecording = true;
    } catch (_) {
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;
      await _cancelRecorderIfNeeded();
      await _deleteRecordingFile();
      rethrow;
    } finally {
      _isStarting = false;
    }
  }

  Future<void> stop() async {
    if (_isDisposed || (!_isRecording && !_isStarting)) {
      return;
    }

    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    if (_isRecording || await _recorder.isRecording()) {
      await _recorder.stop();
    }

    _isRecording = false;
    _isStarting = false;
    _addVolume(0);
    await _deleteRecordingFile();
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    await stop();
    await _recorder.dispose();
    await _volumeController.close();
    _isDisposed = true;
  }

  void _handleAmplitude(Amplitude amplitude) {
    final normalized = dbToNormalizedVolume(amplitude.current);
    _smoothedVolume = smoothRecorderVolume(
      previous: _smoothedVolume,
      current: normalized,
      attack: attack,
      release: release,
    );
    _addVolume(_smoothedVolume);
  }

  void _addVolume(double volume) {
    if (!_volumeController.isClosed) {
      _volumeController.add(volume.clamp(0.0, 1.0).toDouble());
    }
  }

  Future<File> _createRecordingFile() async {
    final directory = await Directory.systemTemp.createTemp(
      'voice_waveform_recording_',
    );
    return File(
      '${directory.path}${Platform.pathSeparator}'
      'recording_${DateTime.now().microsecondsSinceEpoch}.m4a',
    );
  }

  Future<void> _deleteRecordingFile() async {
    final file = _recordingFile;
    _recordingFile = null;
    if (file == null) {
      return;
    }

    try {
      if (await file.exists()) {
        await file.delete();
      }
      final parent = file.parent;
      if (await parent.exists()) {
        await parent.delete();
      }
    } on FileSystemException {
      // Temporary recording cleanup is best effort.
    }
  }

  Future<void> _cancelRecorderIfNeeded() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.cancel();
      }
    } catch (_) {
      // If startup failed before the platform recorder was ready, there is
      // nothing else to clean up here.
    }
  }
}

double dbToNormalizedVolume(double db, {double minDb = -60, double maxDb = 0}) {
  if (!db.isFinite) {
    return 0;
  }

  return ((db - minDb) / (maxDb - minDb)).clamp(0.0, 1.0).toDouble();
}

double smoothRecorderVolume({
  required double previous,
  required double current,
  double attack = 0.72,
  double release = 0.22,
}) {
  final clampedPrevious = previous.clamp(0.0, 1.0).toDouble();
  final clampedCurrent = current.clamp(0.0, 1.0).toDouble();
  final coefficient = clampedCurrent > clampedPrevious ? attack : release;
  return clampedPrevious + (clampedCurrent - clampedPrevious) * coefficient;
}
