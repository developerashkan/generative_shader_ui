import 'dart:ui' show Color, lerpDouble;

import 'package:flutter/foundation.dart';

/// A set of four colors that drives every shader in this package.
///
/// Each shader uses the four colors differently (blob colors for the orb,
/// wave colors for `SiriWave`, a cyclic sweep for neon borders,
/// a start-to-end ramp for progress indicators), so one palette gives a
/// coherent look across all widgets.
///
/// Use one of the presets such as [ShaderPalette.siri] or
/// [ShaderPalette.neon], or build your own:
///
/// ```dart
/// const brand = ShaderPalette(
///   Color(0xFF00E5FF),
///   Color(0xFF7C4DFF),
///   Color(0xFFFF4081),
///   Color(0xFF1A1033),
/// );
/// ```
///
/// Changing the palette of a mounted widget smoothly cross-fades to the
/// new colors.
@immutable
class ShaderPalette {
  /// Creates a palette from four colors.
  const ShaderPalette(this.color1, this.color2, this.color3, this.color4);

  /// Creates a palette from any non-empty list of colors.
  ///
  /// Lists shorter than four are cycled, longer lists are sampled evenly.
  factory ShaderPalette.fromColors(List<Color> colors) {
    assert(colors.isNotEmpty, 'ShaderPalette.fromColors needs a color');
    if (colors.length == 4) {
      return ShaderPalette(colors[0], colors[1], colors[2], colors[3]);
    }
    Color pick(int i) {
      if (colors.length < 4) return colors[i % colors.length];
      return colors[(i * (colors.length - 1) / 3).round()];
    }

    return ShaderPalette(pick(0), pick(1), pick(2), pick(3));
  }

  /// Creates a palette of tints and shades derived from a single [color].
  factory ShaderPalette.monochrome(Color color) {
    Color shade(double f) => Color.from(
          alpha: color.a,
          red: (color.r * f).clamp(0.0, 1.0),
          green: (color.g * f).clamp(0.0, 1.0),
          blue: (color.b * f).clamp(0.0, 1.0),
        );
    Color tint(double f) => Color.from(
          alpha: color.a,
          red: color.r + (1 - color.r) * f,
          green: color.g + (1 - color.g) * f,
          blue: color.b + (1 - color.b) * f,
        );
    return ShaderPalette(tint(0.35), color, shade(0.7), shade(0.25));
  }

  /// The first color: primary highlight.
  final Color color1;

  /// The second color.
  final Color color2;

  /// The third color.
  final Color color3;

  /// The fourth color: usually the deepest tone (orb core, ramp end).
  final Color color4;

  /// The four colors as a list.
  List<Color> get colors => <Color>[color1, color2, color3, color4];

  /// Returns a copy with the given colors replaced.
  ShaderPalette copyWith({
    Color? color1,
    Color? color2,
    Color? color3,
    Color? color4,
  }) {
    return ShaderPalette(
      color1 ?? this.color1,
      color2 ?? this.color2,
      color3 ?? this.color3,
      color4 ?? this.color4,
    );
  }

  /// Linearly interpolates between two palettes.
  static ShaderPalette lerp(ShaderPalette a, ShaderPalette b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    return ShaderPalette(
      _lerpColor(a.color1, b.color1, t),
      _lerpColor(a.color2, b.color2, t),
      _lerpColor(a.color3, b.color3, t),
      _lerpColor(a.color4, b.color4, t),
    );
  }

  static Color _lerpColor(Color a, Color b, double t) {
    return Color.from(
      alpha: lerpDouble(a.a, b.a, t)!,
      red: lerpDouble(a.r, b.r, t)!,
      green: lerpDouble(a.g, b.g, t)!,
      blue: lerpDouble(a.b, b.b, t)!,
    );
  }

  /// Apple-Siri inspired cyan, violet and pink over deep indigo.
  static const ShaderPalette siri = ShaderPalette(
    Color(0xFF2AF5FF),
    Color(0xFF8B5CF6),
    Color(0xFFFF3EA5),
    Color(0xFF1B1464),
  );

  /// Saturated cyber neon: cyan, magenta, yellow and electric violet.
  static const ShaderPalette neon = ShaderPalette(
    Color(0xFF00F0FF),
    Color(0xFFFF00E5),
    Color(0xFFFFE600),
    Color(0xFF7A00FF),
  );

  /// Northern lights greens and blues with a violet edge.
  static const ShaderPalette aurora = ShaderPalette(
    Color(0xFF00FFA3),
    Color(0xFF00B3FF),
    Color(0xFFB967FF),
    Color(0xFF0B3D3A),
  );

  /// Warm coral, orange and gold fading into purple.
  static const ShaderPalette sunset = ShaderPalette(
    Color(0xFFFF6B6B),
    Color(0xFFFFA94D),
    Color(0xFFFFD43B),
    Color(0xFF7048E8),
  );

  /// Deep sea blues and turquoise.
  static const ShaderPalette ocean = ShaderPalette(
    Color(0xFF00B4D8),
    Color(0xFF0077B6),
    Color(0xFF90E0EF),
    Color(0xFF03045E),
  );

  /// Hot pink and ice cyan on midnight.
  static const ShaderPalette cyberpunk = ShaderPalette(
    Color(0xFFFF2A6D),
    Color(0xFF05D9E8),
    Color(0xFFD1F7FF),
    Color(0xFF240046),
  );

  /// Molten reds, orange and magenta.
  static const ShaderPalette lava = ShaderPalette(
    Color(0xFFFF4D00),
    Color(0xFFFF9E00),
    Color(0xFFFF0054),
    Color(0xFF3D0000),
  );

  /// Fresh mint, lime and aqua.
  static const ShaderPalette mint = ShaderPalette(
    Color(0xFF2DD4BF),
    Color(0xFFA3E635),
    Color(0xFF67E8F9),
    Color(0xFF064E3B),
  );

  /// Soft pastel candy colors.
  static const ShaderPalette candy = ShaderPalette(
    Color(0xFFFF9AF5),
    Color(0xFF9AD0FF),
    Color(0xFFFFF59A),
    Color(0xFFB69AFF),
  );

  /// Icy whites and pale blues; the default for snow particles.
  static const ShaderPalette frost = ShaderPalette(
    Color(0xFFFFFFFF),
    Color(0xFFD6ECFF),
    Color(0xFFA5D8FF),
    Color(0xFF1C2A4A),
  );

  /// Warm firefly yellows and greens on a forest night.
  static const ShaderPalette firefly = ShaderPalette(
    Color(0xFFFFF27A),
    Color(0xFFB8FF5C),
    Color(0xFFFFC94D),
    Color(0xFF0E2A1F),
  );

  /// All built-in presets by name, handy for pickers and demos.
  static const Map<String, ShaderPalette> presets = <String, ShaderPalette>{
    'siri': siri,
    'neon': neon,
    'aurora': aurora,
    'sunset': sunset,
    'ocean': ocean,
    'cyberpunk': cyberpunk,
    'lava': lava,
    'mint': mint,
    'candy': candy,
    'frost': frost,
    'firefly': firefly,
  };

  @override
  bool operator ==(Object other) {
    return other is ShaderPalette &&
        other.color1 == color1 &&
        other.color2 == color2 &&
        other.color3 == color3 &&
        other.color4 == color4;
  }

  @override
  int get hashCode => Object.hash(color1, color2, color3, color4);

  @override
  String toString() => 'ShaderPalette($color1, $color2, $color3, $color4)';
}
