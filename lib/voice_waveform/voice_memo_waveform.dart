import 'package:flutter/material.dart';

import 'waveform_controller.dart';
import 'waveform_painter.dart';

class VoiceMemoWaveform extends StatefulWidget {
  const VoiceMemoWaveform({
    super.key,
    required this.volumeStream,
    this.height = 72.0,
    this.barWidth = 6.0,
    this.barGap = 6.0,
  });

  final Stream<double> volumeStream;
  final double height;
  final double barWidth;
  final double barGap;

  @override
  State<VoiceMemoWaveform> createState() => _VoiceMemoWaveformState();
}

class _VoiceMemoWaveformState extends State<VoiceMemoWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late WaveformController _waveformController;

  @override
  void initState() {
    super.initState();
    _waveformController = _createWaveformController();
    _waveformController.start();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant VoiceMemoWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.volumeStream != widget.volumeStream ||
        oldWidget.barWidth != widget.barWidth ||
        oldWidget.barGap != widget.barGap) {
      _waveformController.dispose();
      _waveformController = _createWaveformController();
      _waveformController.start();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _waveformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) {
            return CustomPaint(
              painter: WaveformPainter(controller: _waveformController),
            );
          },
        ),
      ),
    );
  }

  WaveformController _createWaveformController() {
    return WaveformController(
      volumeStream: widget.volumeStream,
      barWidth: widget.barWidth,
      barGap: widget.barGap,
    );
  }
}
