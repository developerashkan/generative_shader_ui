import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:generative_shader_ui/generative_shader_ui.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 400, child: child))),
    );

void main() {
  group('ShaderPalette', () {
    test('fromColors cycles short lists and samples long lists', () {
      final ShaderPalette two = ShaderPalette.fromColors(
        const <Color>[Color(0xFFFF0000), Color(0xFF00FF00)],
      );
      expect(two.color3, const Color(0xFFFF0000));
      expect(two.color4, const Color(0xFF00FF00));

      final ShaderPalette seven = ShaderPalette.fromColors(
        List<Color>.generate(7, (int i) => Color(0xFF000000 + i)),
      );
      expect(seven.color1, const Color(0xFF000000));
      expect(seven.color4, const Color(0xFF000006));
    });

    test('lerp endpoints and equality', () {
      expect(
        ShaderPalette.lerp(ShaderPalette.siri, ShaderPalette.neon, 0),
        ShaderPalette.siri,
      );
      expect(
        ShaderPalette.lerp(ShaderPalette.siri, ShaderPalette.neon, 1),
        ShaderPalette.neon,
      );
      expect(ShaderPalette.siri.copyWith(), ShaderPalette.siri);
      expect(ShaderPalette.presets, hasLength(9));
    });

    test('monochrome keeps the base color', () {
      const Color base = Color(0xFF3366CC);
      expect(ShaderPalette.monochrome(base).color2, base);
    });
  });

  testWidgets('every widget builds, animates and disposes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ListView(
          children: <Widget>[
            const SiriOrb(size: 120, amplitude: 0.5),
            const SiriWave(height: 60),
            NeonButton(onPressed: () {}, child: const Text('Go')),
            const NeonContainer(child: Text('Neon')),
            const ShaderGradient(height: 80, child: Text('Gradient')),
            const AuroraBackground(height: 80),
            const ShaderCircularProgressIndicator(value: 0.4),
            const ShaderCircularProgressIndicator(),
            const ShaderLinearProgressIndicator(value: 0.4),
            const ShaderLinearProgressIndicator(),
            const ShaderGradientText('Hello'),
          ],
        ),
      ),
    );
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Go'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('NeonButton taps, disables and exposes semantics', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      _wrap(NeonButton(onPressed: () => taps++, child: const Text('Tap'))),
    );
    await tester.tap(find.text('Tap'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(NeonButton)),
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
        label: 'Tap',
      ),
    );

    await tester.pumpWidget(
      _wrap(const NeonButton(onPressed: null, child: Text('Tap'))),
    );
    await tester.tap(find.text('Tap'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
  });

  testWidgets('palette changes cross-fade without errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const SiriOrb()));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(_wrap(const SiriOrb(palette: ShaderPalette.lava)));
    for (int i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress indicators report their value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          children: <Widget>[
            ShaderCircularProgressIndicator(value: 0.25, semanticsLabel: 'c'),
            ShaderLinearProgressIndicator(value: 0.75, semanticsLabel: 'l'),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('c'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('l')).value,
      '75%',
    );
  });

  testWidgets('respects reduce motion and animate: false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _wrap(const ShaderGradient(height: 50, animate: false)),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    // The ticker stops once settled, so no frames remain scheduled.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  test('ShaderEffect asset keys point into the package', () {
    for (final ShaderEffect e in ShaderEffect.values) {
      expect(e.assetKey, startsWith('packages/generative_shader_ui/shaders/'));
      expect(e.assetKey, endsWith('.frag'));
    }
  });
}
