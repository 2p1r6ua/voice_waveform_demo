import 'dart:async';

import 'package:flutter/foundation.dart';

import 'display_volume_normalizer.dart';

class VoiceMemoWaveformController extends ChangeNotifier {
  bool _isPaused = false;
  int _clearGeneration = 0;
  double _lastDisplayVolume = 0;
  double _lastEstimatedBarHeight = 12;

  bool get isPaused => _isPaused;

  int get clearGeneration => _clearGeneration;

  double get lastDisplayVolume => _lastDisplayVolume;

  double get lastEstimatedBarHeight => _lastEstimatedBarHeight;

  void clear() {
    _clearGeneration++;
    _lastDisplayVolume = 0;
    _lastEstimatedBarHeight = 12;
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
    required double displayVolume,
    required double estimatedBarHeight,
  }) {
    _lastDisplayVolume = displayVolume.clamp(0.0, 1.0).toDouble();
    _lastEstimatedBarHeight = estimatedBarHeight;
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
    this.attack = 0.75,
    this.release = 0.22,
    this.displayVolumeNormalizer = const DisplayVolumeNormalizer(),
    this.publicController,
  });

  final Stream<double> volumeStream;
  final Duration sampleInterval;
  final double barWidth;
  final double barGap;
  final double minBarHeight;
  final double maxBarHeight;
  final int maxVisibleSamples;
  final double attack;
  final double release;
  final DisplayVolumeNormalizer displayVolumeNormalizer;
  final VoiceMemoWaveformController? publicController;

  final List<double> _volumes = <double>[];
  StreamSubscription<double>? _subscription;
  DateTime? _lastSampleAt;
  double _smoothedVolume = 0.0;
  bool _hasSample = false;
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

      final displayVolume = displayVolumeNormalizer.normalizeVolume(volume);
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
        displayVolume: storedVolume,
        estimatedBarHeight:
            minBarHeight + storedVolume * (maxBarHeight - minBarHeight),
      );
    });
  }

  void clear() {
    _volumes.clear();
    _smoothedVolume = 0;
    _hasSample = false;
    _lastSampleAt = null;
    _handledClearGeneration = publicController?.clearGeneration ?? 0;
    publicController?._updateDebugSnapshot(
      displayVolume: 0,
      estimatedBarHeight: minBarHeight,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  bool get _isPaused => publicController?.isPaused ?? false;

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
