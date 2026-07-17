import 'package:colorrush/core/prefs.dart';
import 'package:colorrush/main.dart';
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
}
