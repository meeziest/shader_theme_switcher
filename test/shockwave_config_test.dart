import 'package:flutter_test/flutter_test.dart';
import 'package:shader_theme_switcher/shockwave_config.dart';

void main() {
  group('ShockwaveConfig', () {
    test('Manual constructor', () {
      const config = ShockwaveConfig(
        shockStrength: 0.5,
        lensingSpread: 0.7,
        powExp: 20.0,
      );
      expect(config.shockStrength, 0.5);
      expect(config.lensingSpread, 0.7);
      expect(config.powExp, 20.0);
      expect(config.maxRadius, null);
    });

    test('Custom values are preserved', () {
      const config = ShockwaveConfig(
        shockStrength: 1.5,
        lensingSpread: 0.2,
        powExp: 10.0,
        maxRadius: 100.0,
      );
      expect(config.shockStrength, 1.5);
      expect(config.lensingSpread, 0.2);
      expect(config.powExp, 10.0);
      expect(config.maxRadius, 100.0);
    });

    test('Preset: liquid', () {
      const config = ShockwaveConfig.liquid;
      expect(config.shockStrength, 1.0);
      expect(config.lensingSpread, 0.3);
      expect(config.powExp, 12.0);
    });

    test('Preset: gentle', () {
      const config = ShockwaveConfig.gentle;
      expect(config.shockStrength, 0.3);
      expect(config.lensingSpread, 0.5);
      expect(config.powExp, 15.0);
    });

    test('Preset: normal', () {
      const config = ShockwaveConfig.normal;
      expect(config.shockStrength, 0);
      expect(config.lensingSpread, 0);
      expect(config.powExp, 0);
    });
  });
}
