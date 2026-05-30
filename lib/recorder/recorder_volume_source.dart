import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

enum MicrophonePermissionResult { granted, denied, permanentlyDenied }

abstract class RecordingVolumeSource {
  Stream<double> get volumeStream;

  Future<void> start();

  Future<void> stop();

  Future<void> dispose();
}

abstract class MicrophonePermissionService {
  Future<MicrophonePermissionResult> request();
}

class PermissionHandlerMicrophonePermissionService
    implements MicrophonePermissionService {
  const PermissionHandlerMicrophonePermissionService({
    this.permission = Permission.microphone,
  });

  final Permission permission;

  @override
  Future<MicrophonePermissionResult> request() async {
    final currentStatus = await permission.status;
    if (currentStatus.isGranted || currentStatus.isPermanentlyDenied) {
      return microphonePermissionResultFromStatus(currentStatus);
    }

    final requestedStatus = await permission.request();
    return microphonePermissionResultFromStatus(requestedStatus);
  }
}

class RecorderPermissionDeniedException implements Exception {
  const RecorderPermissionDeniedException();

  @override
  String toString() => 'Microphone permission was denied.';
}

class RecorderPermissionPermanentlyDeniedException implements Exception {
  const RecorderPermissionPermanentlyDeniedException();

  @override
  String toString() => 'Microphone permission was permanently denied.';
}

class RecorderStartException implements Exception {
  const RecorderStartException(this.cause);

  final Object cause;

  @override
  String toString() => 'Recording failed to start: $cause';
}

class RecorderVolumeSource implements RecordingVolumeSource {
  RecorderVolumeSource({
    AudioRecorder? recorder,
    MicrophonePermissionService? permissionService,
    this.amplitudeInterval = const Duration(milliseconds: 80),
    this.floorDb = -45.0,
    this.ceilingDb = -12.0,
    this.attack = 0.75,
    this.release = 0.22,
  }) : _recorder = recorder ?? AudioRecorder(),
       _permissionService =
           permissionService ??
           const PermissionHandlerMicrophonePermissionService();

  final AudioRecorder _recorder;
  final MicrophonePermissionService _permissionService;
  final Duration amplitudeInterval;
  final double floorDb;
  final double ceilingDb;
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

  @override
  Stream<double> get volumeStream => _volumeController.stream;

  bool get isRecording => _isRecording;

  @override
  Future<void> start() async {
    if (_isDisposed || _isRecording || _isStarting) {
      return;
    }

    _isStarting = true;
    try {
      await _ensureMicrophonePermission();

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
    } on RecorderPermissionDeniedException {
      await _cleanupAfterFailedStart();
      rethrow;
    } on RecorderPermissionPermanentlyDeniedException {
      await _cleanupAfterFailedStart();
      rethrow;
    } catch (error) {
      await _cleanupAfterFailedStart();
      throw RecorderStartException(error);
    } finally {
      _isStarting = false;
    }
  }

  @override
  Future<void> stop() async {
    if (_isDisposed || (!_isRecording && !_isStarting)) {
      return;
    }

    await _stopInternal(addSilenceSample: true);
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    await _stopInternal(addSilenceSample: false);
    await _recorder.dispose();
    await _volumeController.close();
    _isDisposed = true;
  }

  Future<void> _ensureMicrophonePermission() async {
    final permissionResult = await _permissionService.request();
    switch (permissionResult) {
      case MicrophonePermissionResult.granted:
        return;
      case MicrophonePermissionResult.denied:
        throw const RecorderPermissionDeniedException();
      case MicrophonePermissionResult.permanentlyDenied:
        throw const RecorderPermissionPermanentlyDeniedException();
    }
  }

  Future<void> _stopInternal({required bool addSilenceSample}) async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    try {
      if (_isRecording || await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {
      await _cancelRecorderIfNeeded();
    } finally {
      _isRecording = false;
      _isStarting = false;
      if (addSilenceSample) {
        _addVolume(0);
      }
      await _deleteRecordingFile();
    }
  }

  Future<void> _cleanupAfterFailedStart() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    await _cancelRecorderIfNeeded();
    await _deleteRecordingFile();
  }

  void _handleAmplitude(Amplitude amplitude) {
    final normalized = dbToNormalizedVolume(
      amplitude.current,
      floorDb: floorDb,
      ceilingDb: ceilingDb,
    );
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

MicrophonePermissionResult microphonePermissionResultFromStatus(
  PermissionStatus status,
) {
  if (status.isGranted) {
    return MicrophonePermissionResult.granted;
  }
  if (status.isPermanentlyDenied) {
    return MicrophonePermissionResult.permanentlyDenied;
  }
  return MicrophonePermissionResult.denied;
}

double dbToNormalizedVolume(
  double db, {
  double floorDb = -45.0,
  double ceilingDb = -12.0,
}) {
  if (!db.isFinite) {
    return 0;
  }

  if (ceilingDb <= floorDb) {
    return 0;
  }

  return ((db - floorDb) / (ceilingDb - floorDb)).clamp(0.0, 1.0).toDouble();
}

double smoothRecorderVolume({
  required double previous,
  required double current,
  double attack = 0.75,
  double release = 0.22,
}) {
  final clampedPrevious = previous.clamp(0.0, 1.0).toDouble();
  final clampedCurrent = current.clamp(0.0, 1.0).toDouble();
  final coefficient = clampedCurrent > clampedPrevious ? attack : release;
  return clampedPrevious + (clampedCurrent - clampedPrevious) * coefficient;
}
