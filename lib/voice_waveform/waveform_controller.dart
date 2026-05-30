import 'dart:async';

import 'package:flutter/foundation.dart';

class WaveformController {
  WaveformController({
    required this.volumeStream,
    this.sampleInterval = const Duration(milliseconds: 80),
    this.barWidth = 6.0,
    this.barGap = 6.0,
    this.maxVisibleSamples = 160,
  });

  final Stream<double> volumeStream;
  final Duration sampleInterval;
  final double barWidth;
  final double barGap;
  final int maxVisibleSamples;

  final List<double> _volumes = <double>[];
  StreamSubscription<double>? _subscription;
  DateTime? _lastSampleAt;

  List<double> get volumes => List<double>.unmodifiable(_volumes);

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
      _volumes.add(volume.clamp(0.0, 1.0).toDouble());
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
