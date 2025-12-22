class ShockwaveConfig {
  const ShockwaveConfig({
    required this.shockStrength,
    required this.lensingSpread,
    required this.powExp,
    this.maxRadius,
  });

  /// Intensity of the distortion (SHOCK_STRENGTH).
  final double shockStrength;

  /// How wide the distortion ring is (LENSING_SPREAD).
  final double lensingSpread;

  /// Sharpness of the wave edge (POW_EXP).
  final double powExp;

  /// How far the wave travels (MAX_RADIUS).
  /// If null, it will be calculated automatically based on the screen size and splash point.
  final double? maxRadius;

  /// A balanced, standard shockwave effect.
  static const ShockwaveConfig normal = ShockwaveConfig(
    shockStrength: 0,
    lensingSpread: 0,
    powExp: 0,
  );

  /// A smooth, viscous liquid effect with wider spread and slower feel.
  static const ShockwaveConfig liquid = ShockwaveConfig(
    shockStrength: 1.0,
    lensingSpread: 0.3,
    powExp: 50.0,
  );

  /// A subtle, gentle wave for minimal distraction.
  static const ShockwaveConfig gentle = ShockwaveConfig(
    shockStrength: 0.3,
    lensingSpread: 0.5,
    powExp: 15.0,
  );
}
