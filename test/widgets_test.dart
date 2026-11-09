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
      expect(ShaderPalette.presets, hasLength(11));
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
            const ShaderSkeleton(child: Text('Skeleton')),
            const ShaderShimmer(child: Text('Shine')),
            const LiquidGlass(child: Text('Glass')),
            for (final ParticleStyle style in ParticleStyle.values)
              SizedBox(height: 40, child: ParticleField(style: style)),
            ShaderRipple(onTap: () {}, child: const Text('Ripple')),
            const ShaderPulse(child: SizedBox.square(dimension: 40)),
            const LiquidWaves(height: 80, level: 0.6),
            for (final RevealStyle style in RevealStyle.values)
              ShaderReveal(progress: 0.5, style: style, child: Text('$style')),
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

  group('ShaderSkeleton', () {
    Widget card({required bool loading, VoidCallback? onTap}) => _wrap(
          ShaderSkeleton(
            isLoading: loading,
            child: Column(
              children: <Widget>[
                const CircleAvatar(radius: 20),
                GestureDetector(onTap: onTap, child: const Text('Title text')),
                const SkeletonBone(width: 80),
                const SkeletonIgnore(child: Text('decor')),
              ],
            ),
          ),
        );

    testWidgets('generates bones from the real layout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(card(loading: true));
      final RenderObject render = tester.renderObject(
        find.byWidgetPredicate(
          (Widget w) => w.runtimeType.toString() == '_SkeletonRender',
        ),
      );
      // Bones for the avatar, the text line and the explicit bone; the
      // ignored text and empty space stay clear.
      expect(
        render,
        paints
          ..clipPath(
            pathMatcher: isPathThat(
              includes: const <Offset>[Offset(200, 20), Offset(200, 50)],
              excludes: const <Offset>[Offset(5, 5), Offset(395, 595)],
            ),
          )
          ..rect(),
      );
    });

    testWidgets('blocks taps and announces loading, then reveals', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(card(loading: true, onTap: () => taps++));
      await tester.tap(find.text('Title text'), warnIfMissed: false);
      expect(taps, 0);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);

      await tester.pumpWidget(card(loading: false, onTap: () => taps++));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Title text'));
      expect(taps, 1);
      expect(find.bySemanticsLabel('Loading'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SkeletonBone variants build outside a skeleton', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: <Widget>[
              SkeletonBone(width: 100),
              SkeletonBone.circle(size: 32),
              SkeletonBone.text(lines: 3),
            ],
          ),
        ),
      );
      expect(tester.getSize(find.byType(SkeletonBone).first).width, 100);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('gesture detectors around shader widgets receive taps', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      _wrap(
        GestureDetector(
          onTap: () => taps++,
          child: const ShaderGradient(height: 80),
        ),
      ),
    );
    await tester.tap(find.byType(ShaderGradient));
    expect(taps, 1);
  });

  testWidgets('ShaderTheme supplies palette, speed and fps cap', (
    WidgetTester tester,
  ) async {
    late ShaderTheme? found;
    await tester.pumpWidget(
      ShaderTheme(
        palette: ShaderPalette.sunset,
        speed: 2,
        maxFps: 30,
        child: _wrap(
          Builder(
            builder: (BuildContext context) {
              found = ShaderTheme.maybeOf(context);
              return const SiriOrb();
            },
          ),
        ),
      ),
    );
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(found?.palette, ShaderPalette.sunset);
    expect(
      const ShaderTheme(animate: false, child: SizedBox())
          .updateShouldNotify(const ShaderTheme(child: SizedBox())),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ShaderRipple taps and controller ripples', (
    WidgetTester tester,
  ) async {
    final ShaderRippleController controller = ShaderRippleController();
    int taps = 0;
    await tester.pumpWidget(
      _wrap(
        ShaderRipple(
          controller: controller,
          onTap: () => taps++,
          borderRadius: BorderRadius.circular(12),
          child: const SizedBox(height: 100, child: Text('Surface')),
        ),
      ),
    );
    await tester.tap(find.text('Surface'));
    controller
      ..ripple()
      ..ripple(const Offset(10, 10));
    for (int i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(taps, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('reveal transitions in switchers, implicit and routes', (
    WidgetTester tester,
  ) async {
    Widget switcher(int n) => _wrap(
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: ShaderReveal.transitionBuilder(
              style: RevealStyle.burn,
            ),
            child: Text('n$n', key: ValueKey<int>(n)),
          ),
        );
    await tester.pumpWidget(switcher(1));
    await tester.pumpWidget(switcher(2));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('n1'), findsOneWidget);
    expect(find.text('n2'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('n1'), findsNothing);

    await tester.pumpWidget(
      _wrap(const AnimatedShaderReveal(visible: false, child: Text('hidden'))),
    );
    await tester.pumpWidget(
      _wrap(const AnimatedShaderReveal(visible: true, child: Text('hidden'))),
    );
    await tester.pumpAndSettle();

    final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: nav, home: const Text('home')),
    );
    nav.currentState!.push(
      ShaderRevealRoute<void>(builder: (_) => const Text('details')),
    );
    await tester.pumpAndSettle();
    expect(find.text('details'), findsOneWidget);
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('details'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ShaderPulse fades out when inactive and stops ticking', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const ShaderPulse(child: SizedBox.square(dimension: 40))),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(
      _wrap(
        const ShaderPulse(
          active: false,
          child: SizedBox.square(dimension: 40),
        ),
      ),
    );
    for (int i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  test('ShaderEffect asset keys point into the package', () {
    for (final ShaderEffect e in ShaderEffect.values) {
      expect(e.assetKey, startsWith('packages/generative_shader_ui/shaders/'));
      expect(e.assetKey, endsWith('.frag'));
    }
  });
}
