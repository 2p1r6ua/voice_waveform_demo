import 'package:flutter/material.dart';

import 'volume_mapper.dart';
import 'waveform_controller.dart';

class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.controller,
    this.volumeMapper = const VolumeMapper(),
    this.barColor = Colors.white,
    this.backgroundColor = Colors.black,
  });

  final WaveformController controller;
  final VolumeMapper volumeMapper;
  final Color barColor;
  final Color backgroundColor;

  late final Paint _backgroundPaint = Paint()..color = backgroundColor;
  late final Paint _barPaint = Paint()
    ..color = barColor
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    final sampleCount = controller.sampleCount;
    if (sampleCount == 0) {
      return;
    }

    final centerY = size.height / 2;
    final rightEdge = size.width - controller.scrollOffset;
    final radius = Radius.circular(controller.barWidth / 2);

    for (var index = sampleCount - 1; index >= 0; index--) {
      final distanceFromNewest = sampleCount - 1 - index;
      final right = rightEdge - distanceFromNewest * controller.pitch;
      final left = right - controller.barWidth;

      if (right < 0) {
        break;
      }
      if (left > size.width) {
        continue;
      }

      final height = volumeMapper.mapToHeight(controller.volumeAt(index));
      final rect = Rect.fromLTWH(
        left,
        centerY - height / 2,
        controller.barWidth,
        height,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), _barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}
