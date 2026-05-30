import 'package:flutter/material.dart';

import 'volume_mapper.dart';
import 'waveform_controller.dart';
import 'waveform_painter.dart';

class VoiceMemoWaveform extends StatefulWidget {
  const VoiceMemoWaveform({
    super.key,
    required this.volumeStream,
    this.height = 72.0,
    this.minBarHeight = 12.0,
    this.maxBarHeight = 58.0,
    this.barWidth = 6.0,
    this.barGap = 6.0,
    this.barColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.barInterval = const Duration(milliseconds: 80),
    this.controller,
  });

  final Stream<double> volumeStream;
  final double height;
  final double minBarHeight;
  final double maxBarHeight;
  final double barWidth;
  final double barGap;
  final Color barColor;
  final Color backgroundColor;
  final Duration barInterval;
  final VoiceMemoWaveformController? controller;

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
        oldWidget.controller != widget.controller ||
        oldWidget.barWidth != widget.barWidth ||
        oldWidget.barGap != widget.barGap ||
        oldWidget.barInterval != widget.barInterval) {
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
              painter: WaveformPainter(
                controller: _waveformController,
                volumeMapper: VolumeMapper(
                  minHeight: widget.minBarHeight,
                  maxHeight: widget.maxBarHeight,
                ),
                barColor: widget.barColor,
                backgroundColor: widget.backgroundColor,
              ),
            );
          },
        ),
      ),
    );
  }

  WaveformController _createWaveformController() {
    return WaveformController(
      volumeStream: widget.volumeStream,
      sampleInterval: widget.barInterval,
      barWidth: widget.barWidth,
      barGap: widget.barGap,
      publicController: widget.controller,
    );
  }
}
