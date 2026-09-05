import 'package:energycore_flutter/app/theme/energycore_theme.dart';
import 'package:energycore_flutter/shared/presentation/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EnergyCore brand renders with the emerald theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EnergyCoreTheme.light,
        home: const Scaffold(body: Center(child: BrandMark())),
      ),
    );

    expect(find.text('EnergyCore'), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('EnergyCore'))).colorScheme.primary,
      EnergyCoreTheme.emeraldStrong,
    );
  });
}
