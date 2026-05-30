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
  double _currentVolume = 0.18;
  int _phraseLength = 0;
  int _phraseTick = 0;

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

      _phase += 0.18 + _random.nextDouble() * 0.08;
      _phraseTick++;

      if (_phraseTick >= _phraseLength) {
        _startNextPhrase();
      }

      final phraseProgress = _phraseProgress();
      final envelope = sin(pi * phraseProgress).clamp(0.0, 1.0).toDouble();
      final formantMovement =
          0.55 + 0.25 * sin(_phase) + 0.12 * sin(_phase * 2.7);
      final breath = 0.05 + _random.nextDouble() * 0.05;
      final target = (0.10 + envelope * formantMovement + breath).clamp(
        0.0,
        1.0,
      );

      _currentVolume += (target - _currentVolume) * 0.28;
      _controller.add(_currentVolume.clamp(0.0, 1.0).toDouble());
    });
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _controller.close();
  }

  int _nextPhraseLength() => 12 + _random.nextInt(18);

  void _startNextPhrase() {
    _phraseLength = _nextPhraseLength();
    _phraseTick = 0;
  }

  double _phraseProgress() => _phraseTick / _phraseLength;
}
