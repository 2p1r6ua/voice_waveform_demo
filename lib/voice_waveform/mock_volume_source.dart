import 'dart:async';
import 'dart:math';

class MockVolumeSource {
  MockVolumeSource({this.interval = const Duration(milliseconds: 80)});

  final Duration interval;

  final StreamController<double> _controller =
      StreamController<double>.broadcast();
  final Random _random = Random();

  Timer? _timer;
  double _phase = 0;
  double _currentVolume = 0.08;
  double _targetEnergy = 0.0;
  int _phraseLength = 0;
  int _phraseTick = 0;
  int _pauseTicksRemaining = 0;

  Stream<double> get stream => _controller.stream;

  void start() {
    if (_timer != null) {
      return;
    }

    _startNextPhrase();
    _timer = Timer.periodic(interval, (_) {
      if (_controller.isClosed) {
        return;
      }

      _targetEnergy = _nextTargetEnergy();
      final coefficient = _targetEnergy > _currentVolume ? 0.62 : 0.22;
      _currentVolume += (_targetEnergy - _currentVolume) * coefficient;
      _controller.add(_currentVolume.clamp(0.0, 1.0).toDouble());
    });
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _controller.close();
  }

  double _nextTargetEnergy() {
    if (_pauseTicksRemaining > 0) {
      _pauseTicksRemaining--;
      if (_pauseTicksRemaining == 0) {
        _startNextPhrase();
      }
      return 0.03 + _random.nextDouble() * 0.04;
    }

    _phase += 0.16 + _random.nextDouble() * 0.07;
    _phraseTick++;

    if (_phraseTick >= _phraseLength) {
      _startPause();
      return 0.04 + _random.nextDouble() * 0.05;
    }

    final phraseProgress = _phraseProgress();
    final fadeIn = _smoothStep((phraseProgress / 0.18).clamp(0.0, 1.0));
    final fadeOut =
        1.0 - _smoothStep(((phraseProgress - 0.76) / 0.24).clamp(0.0, 1.0));
    final envelope = fadeIn * fadeOut;
    final syllablePulse = 0.62 + 0.22 * sin(_phase) + 0.10 * sin(_phase * 2.35);
    final breathNoise = (_random.nextDouble() - 0.5) * 0.08;

    return (0.08 + envelope * syllablePulse + breathNoise).clamp(0.0, 1.0);
  }

  int _nextPhraseLength() => 14 + _random.nextInt(20);

  int _nextPauseLength() => 2 + _random.nextInt(5);

  void _startNextPhrase() {
    _phraseLength = _nextPhraseLength();
    _phraseTick = 0;
    _pauseTicksRemaining = 0;
  }

  void _startPause() {
    _pauseTicksRemaining = _nextPauseLength();
    _phraseTick = 0;
  }

  double _phraseProgress() => _phraseTick / _phraseLength;

  double _smoothStep(double value) => value * value * (3 - 2 * value);
}
