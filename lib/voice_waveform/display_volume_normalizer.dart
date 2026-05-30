import 'dart:math';

class DisplayVolumeNormalizer {
  const DisplayVolumeNormalizer({
    this.noiseGate = 0.16,
    this.contrastExponent = 1.55,
    this.floorDb = -45.0,
    this.ceilingDb = -8.0,
  }) : assert(noiseGate >= 0 && noiseGate < 1),
       assert(contrastExponent > 0),
       assert(ceilingDb > floorDb);

  final double noiseGate;
  final double contrastExponent;
  final double floorDb;
  final double ceilingDb;

  double normalizeVolume(double volume) {
    if (!volume.isFinite) {
      return 0;
    }

    final normalized = volume.clamp(0.0, 1.0).toDouble();
    final gated = _applyNoiseGate(normalized);
    return pow(gated, contrastExponent).clamp(0.0, 1.0).toDouble();
  }

  double normalizeDb(double db) {
    return normalizeVolume(dbToVolume(db));
  }

  double dbToVolume(double db) {
    if (!db.isFinite) {
      return 0;
    }

    return ((db - floorDb) / (ceilingDb - floorDb)).clamp(0.0, 1.0).toDouble();
  }

  double _applyNoiseGate(double normalized) {
    if (normalized < noiseGate) {
      return 0;
    }

    return ((normalized - noiseGate) / (1.0 - noiseGate))
        .clamp(0.0, 1.0)
        .toDouble();
  }
}
