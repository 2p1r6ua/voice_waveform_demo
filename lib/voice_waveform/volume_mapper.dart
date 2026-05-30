import 'dart:math';

class VolumeMapper {
  const VolumeMapper({
    this.minHeight = 12.0,
    this.maxHeight = 58.0,
    this.exponent = 0.6,
  });

  final double minHeight;
  final double maxHeight;
  final double exponent;

  double mapToHeight(double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0).toDouble();
    final curvedVolume = pow(clampedVolume, exponent).toDouble();
    return minHeight + curvedVolume * (maxHeight - minHeight);
  }
}
