import 'package:colorrush/core/prefs.dart';
import 'package:colorrush/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Prefs.init();
  });

  testWidgets('home screen renders and navigates into a game', (tester) async {
    await tester.pumpWidget(const ColorRushApp());
    await tester.pumpAndSettle();

    // Home essentials (English strings - test env locale defaults to en).
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.textContaining('BEST'), findsWidgets);

    // Enter the game.
    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();
    expect(find.text('TAP TO START'), findsOneWidget);

    // Start a run: a color word must appear, timer starts.
    await tester.tap(find.text('TAP TO START'));
    await tester.pump(const Duration(milliseconds: 200));
    const names = ['RED', 'BLUE', 'GREEN', 'YELLOW', 'PURPLE', 'ORANGE'];
    final wordVisible = names.any((n) => tester.any(find.text(n)));
    expect(wordVisible, isTrue,
        reason: 'a color word should be displayed during play');

    // Answer buttons visible.
    expect(find.text('MATCH'), findsOneWidget);
    expect(find.text('NO MATCH'), findsOneWidget);

    // Let the timer run out -> game over overlay appears.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('RETRY'), findsOneWidget);
  });

  testWidgets('how-to-play dialog opens from home', (tester) async {
    await tester.pumpWidget(const ColorRushApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('How to play'));
    await tester.pumpAndSettle();
    expect(find.text('How to play'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  for (final bottomInset in [24.0, 48.0]) {
    testWidgets('home and game respect edge-to-edge insets ($bottomInset)',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(432, 960);
      final insets = FakeViewPadding(
        top: 32,
        bottom: bottomInset,
        left: 16,
        right: 16,
      );
      tester.view.viewPadding = insets;
      tester.view.padding = insets;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ColorRushApp());
      await tester.pumpAndSettle();

      void expectSafeContent() {
        final safeArea = tester.widget<SafeArea>(find.byType(SafeArea).first);
        expect(
          tester.getRect(find.byWidget(safeArea.child)),
          Rect.fromLTRB(16, 32, 416, 960 - bottomInset),
        );
        expect(tester.takeException(), isNull);
      }

      expectSafeContent();
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      expect(region.value.statusBarIconBrightness, Brightness.light);
      expect(region.value.systemNavigationBarIconBrightness, Brightness.light);
      expect(region.value.statusBarColor, isNull);
      expect(region.value.systemNavigationBarColor, isNull);
      expect(region.value.systemNavigationBarDividerColor, isNull);

      await tester.tap(find.text('PLAY'));
      await tester.pumpAndSettle();
      expect(find.text('TAP TO START'), findsOneWidget);
      expectSafeContent();
      expect(
        tester.getBottomRight(find.text('MATCH')).dy,
        lessThanOrEqualTo(960 - bottomInset),
      );

      // Insets can change when Android switches navigation mode.
      tester.view.viewPadding = const FakeViewPadding(top: 48, bottom: 64);
      tester.view.padding = const FakeViewPadding(top: 48, bottom: 64);
      await tester.pump();
      final safeArea = tester.widget<SafeArea>(find.byType(SafeArea).first);
      expect(
        tester.getRect(find.byWidget(safeArea.child)),
        const Rect.fromLTRB(0, 48, 432, 896),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
