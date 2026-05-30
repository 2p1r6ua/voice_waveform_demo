import 'dart:async';

import 'package:flutter/foundation.dart';

import 'display_volume_normalizer.dart';

class VoiceMemoWaveformController extends ChangeNotifier {
  bool _isPaused = false;
  int _clearGeneration = 0;
  double _lastRawVolume = 0;
  double _lastNormalizedVolume = 0;
  double _lastDisplayVolume = 0;
  double _lastSmoothedVolume = 0;
  double _lastEstimatedBarHeight = 12;
  bool _lastImpulseSuppressed = false;

  bool get isPaused => _isPaused;

  int get clearGeneration => _clearGeneration;

  double get lastRawVolume => _lastRawVolume;

  double get lastNormalizedVolume => _lastNormalizedVolume;

  double get lastDisplayVolume => _lastDisplayVolume;

  double get lastSmoothedVolume => _lastSmoothedVolume;

  double get lastEstimatedBarHeight => _lastEstimatedBarHeight;

  bool get lastImpulseSuppressed => _lastImpulseSuppressed;

  void clear() {
    _clearGeneration++;
    _lastRawVolume = 0;
    _lastNormalizedVolume = 0;
    _lastDisplayVolume = 0;
    _lastSmoothedVolume = 0;
    _lastEstimatedBarHeight = 12;
    _lastImpulseSuppressed = false;
    notifyListeners();
  }

  void pause() {
    if (_isPaused) {
      return;
    }
    _isPaused = true;
    notifyListeners();
  }

  void resume() {
    if (!_isPaused) {
      return;
    }
    _isPaused = false;
    notifyListeners();
  }

  void _updateDebugSnapshot({
    required double rawVolume,
    required double normalizedVolume,
    required double displayVolume,
    required double smoothedVolume,
    required double estimatedBarHeight,
    required bool impulseSuppressed,
  }) {
    _lastRawVolume = rawVolume.clamp(0.0, 1.0).toDouble();
    _lastNormalizedVolume = normalizedVolume.clamp(0.0, 1.0).toDouble();
    _lastDisplayVolume = displayVolume.clamp(0.0, 1.0).toDouble();
    _lastSmoothedVolume = smoothedVolume.clamp(0.0, 1.0).toDouble();
    _lastEstimatedBarHeight = estimatedBarHeight;
    _lastImpulseSuppressed = impulseSuppressed;
    notifyListeners();
  }
}

class WaveformController {
  WaveformController({
    required this.volumeStream,
    this.sampleInterval = const Duration(milliseconds: 80),
    this.barWidth = 6.0,
    this.barGap = 6.0,
    this.minBarHeight = 12.0,
    this.maxBarHeight = 58.0,
    this.maxVisibleSamples = 160,
    this.attack = 0.50,
    this.release = 0.18,
    this.maxRisePerTick = 0.18,
    this.medianWindow = 3,
    this.impulseSuppressionEnabled = true,
    this.impulseThreshold = 0.45,
    this.impulseDamping = 0.35,
    this.sustainFrames = 2,
    this.displayVolumeNormalizer = const DisplayVolumeNormalizer(),
    this.publicController,
  }) : assert(maxRisePerTick >= 0),
       assert(medianWindow >= 1),
       assert(impulseThreshold >= 0),
       assert(impulseDamping >= 0 && impulseDamping <= 1),
       assert(sustainFrames >= 1);

  final Stream<double> volumeStream;
  final Duration sampleInterval;
  final double barWidth;
  final double barGap;
  final double minBarHeight;
  final double maxBarHeight;
  final int maxVisibleSamples;
  final double attack;
  final double release;
  final double maxRisePerTick;
  final int medianWindow;
  final bool impulseSuppressionEnabled;
  final double impulseThreshold;
  final double impulseDamping;
  final int sustainFrames;
  final DisplayVolumeNormalizer displayVolumeNormalizer;
  final VoiceMemoWaveformController? publicController;

  final List<double> _volumes = <double>[];
  final List<double> _medianValues = <double>[];
  StreamSubscription<double>? _subscription;
  DateTime? _lastSampleAt;
  double _smoothedVolume = 0.0;
  double _lastProcessedDisplayVolume = 0.0;
  bool _hasSample = false;
  int _highFrameCount = 0;
  int _handledClearGeneration = 0;

  int get sampleCount => _volumes.length;

  double volumeAt(int index) => _volumes[index];

  double get pitch => barWidth + barGap;

  double get scrollOffset {
    if (_isPaused) {
      return 0;
    }

    final lastSampleAt = _lastSampleAt;
    if (lastSampleAt == null) {
      return 0;
    }

    final elapsed = DateTime.now().difference(lastSampleAt);
    final progress = elapsed.inMicroseconds / sampleInterval.inMicroseconds;
    return clampDouble(progress, 0, 1) * pitch;
  }

  void start() {
    _subscription ??= volumeStream.listen((volume) {
      _handleClearRequest();
      if (_isPaused) {
        return;
      }

      final rawVolume = volume.isFinite
          ? volume.clamp(0.0, 1.0).toDouble()
          : 0.0;
      final normalizedVolume = rawVolume;
      final displayCandidate = displayVolumeNormalizer.normalizeVolume(
        normalizedVolume,
      );
      final filteredVolume = _medianFilter(displayCandidate);
      final impulseResult = _suppressImpulseIfNeeded(filteredVolume);
      final displayVolume = _limitRise(impulseResult.volume);

      if (!_hasSample) {
        _smoothedVolume = displayVolume;
        _hasSample = true;
      } else {
        final coefficient = displayVolume > _smoothedVolume ? attack : release;
        _smoothedVolume += (displayVolume - _smoothedVolume) * coefficient;
      }

      final storedVolume = _smoothedVolume.clamp(0.0, 1.0).toDouble();
      _volumes.add(storedVolume);
      if (_volumes.length > maxVisibleSamples) {
        _volumes.removeRange(0, _volumes.length - maxVisibleSamples);
      }
      _lastSampleAt = DateTime.now();
      publicController?._updateDebugSnapshot(
        rawVolume: rawVolume,
        normalizedVolume: normalizedVolume,
        displayVolume: displayVolume,
        smoothedVolume: storedVolume,
        estimatedBarHeight:
            minBarHeight + storedVolume * (maxBarHeight - minBarHeight),
        impulseSuppressed: impulseResult.wasSuppressed,
      );
    });
  }

  void clear() {
    _volumes.clear();
    _medianValues.clear();
    _smoothedVolume = 0;
    _lastProcessedDisplayVolume = 0;
    _hasSample = false;
    _highFrameCount = 0;
    _lastSampleAt = null;
    _handledClearGeneration = publicController?.clearGeneration ?? 0;
    publicController?._updateDebugSnapshot(
      rawVolume: 0,
      normalizedVolume: 0,
      displayVolume: 0,
      smoothedVolume: 0,
      estimatedBarHeight: minBarHeight,
      impulseSuppressed: false,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  bool get _isPaused => publicController?.isPaused ?? false;

  double _medianFilter(double value) {
    _medianValues.add(value.clamp(0.0, 1.0).toDouble());
    if (_medianValues.length > medianWindow) {
      _medianValues.removeRange(0, _medianValues.length - medianWindow);
    }

    final sorted = List<double>.of(_medianValues)..sort();
    final middle = (sorted.length - 1) ~/ 2;
    return sorted[middle];
  }

  _ImpulseResult _suppressImpulseIfNeeded(double value) {
    final clampedValue = value.clamp(0.0, 1.0).toDouble();
    final previous = _lastProcessedDisplayVolume;
    final suddenRise = clampedValue - previous > impulseThreshold;
    final hasSustain = _highFrameCount >= sustainFrames;
    var wasSuppressed = false;
    var processed = clampedValue;

    if (impulseSuppressionEnabled && suddenRise && !hasSustain) {
      processed = previous + (clampedValue - previous) * impulseDamping;
      wasSuppressed = true;
    }

    if (clampedValue >= impulseThreshold) {
      _highFrameCount++;
    } else {
      _highFrameCount = 0;
    }

    return _ImpulseResult(
      volume: processed.clamp(0.0, 1.0).toDouble(),
      wasSuppressed: wasSuppressed,
    );
  }

  double _limitRise(double value) {
    final clampedValue = value.clamp(0.0, 1.0).toDouble();
    final allowed = _lastProcessedDisplayVolume + maxRisePerTick;
    final limited = clampedValue > allowed ? allowed : clampedValue;
    _lastProcessedDisplayVolume = limited.clamp(0.0, 1.0).toDouble();
    return _lastProcessedDisplayVolume;
  }

  void _handleClearRequest() {
    final controller = publicController;
    if (controller == null) {
      return;
    }
    if (controller.clearGeneration != _handledClearGeneration) {
      clear();
    }
  }
}

class _ImpulseResult {
  const _ImpulseResult({required this.volume, required this.wasSuppressed});

  final double volume;
  final bool wasSuppressed;
}
