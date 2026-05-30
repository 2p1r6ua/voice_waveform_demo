import 'package:flutter/material.dart';

import 'volume_mapper.dart';
import 'waveform_controller.dart';

class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.controller,
    this.volumeMapper = const VolumeMapper(),
    this.barColor = Colors.white,
  });

  final WaveformController controller;
  final VolumeMapper volumeMapper;
  final Color barColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final volumes = controller.volumes;
    if (volumes.isEmpty) {
      return;
    }

    final centerY = size.height / 2;
    final rightEdge = size.width - controller.scrollOffset;

    for (var index = volumes.length - 1; index >= 0; index--) {
      final distanceFromNewest = volumes.length - 1 - index;
      final right = rightEdge - distanceFromNewest * controller.pitch;
      final left = right - controller.barWidth;

      if (right < 0) {
        break;
      }
      if (left > size.width) {
        continue;
      }

      final height = volumeMapper.mapToHeight(volumes[index]);
      final rect = Rect.fromLTWH(
        left,
        centerY - height / 2,
        controller.barWidth,
        height,
      );
      final radius = Radius.circular(controller.barWidth / 2);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}
