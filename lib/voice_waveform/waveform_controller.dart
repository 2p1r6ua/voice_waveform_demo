import 'dart:async';

import 'package:flutter/foundation.dart';

class WaveformController {
  WaveformController({
    required this.volumeStream,
    this.sampleInterval = const Duration(milliseconds: 80),
    this.barWidth = 6.0,
    this.barGap = 6.0,
    this.maxVisibleSamples = 160,
    this.attack = 0.68,
    this.release = 0.24,
  });

  final Stream<double> volumeStream;
  final Duration sampleInterval;
  final double barWidth;
  final double barGap;
  final int maxVisibleSamples;
  final double attack;
  final double release;

  final List<double> _volumes = <double>[];
  StreamSubscription<double>? _subscription;
  DateTime? _lastSampleAt;
  double _smoothedVolume = 0.0;
  bool _hasSample = false;

  int get sampleCount => _volumes.length;

  double volumeAt(int index) => _volumes[index];

  double get pitch => barWidth + barGap;

  double get scrollOffset {
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
      final clampedVolume = volume.clamp(0.0, 1.0).toDouble();
      if (!_hasSample) {
        _smoothedVolume = clampedVolume;
        _hasSample = true;
      } else {
        final coefficient = clampedVolume > _smoothedVolume ? attack : release;
        _smoothedVolume += (clampedVolume - _smoothedVolume) * coefficient;
      }

      _volumes.add(_smoothedVolume.clamp(0.0, 1.0).toDouble());
      if (_volumes.length > maxVisibleSamples) {
        _volumes.removeRange(0, _volumes.length - maxVisibleSamples);
      }
      _lastSampleAt = DateTime.now();
    });
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
