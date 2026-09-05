import 'package:energycore_flutter/app/localization/app_strings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const requiredKeys = [
    'deviceControlTitle',
    'spaces',
    'alertsCenter',
    'energyCenter',
    'service',
    'billing',
    'platformTitle',
    'resetPassword',
    'newAlert',
    'samplingInterval',
    'upgradePlanFeature',
    'targetType',
    'customInterval',
    'internalRoutines',
    'applyRuleProfile',
    'preserveCriticalSound',
    'allowedSources',
    'routineNightSilence',
    'deliveryMode',
  ];

  for (final locale in AppStrings.supportedLocales) {
    test('core modules are translated for ${locale.languageCode}', () {
      final strings = AppStrings(Locale(locale.languageCode));
      for (final key in requiredKeys) {
        expect(strings.text(key), isNot(key));
      }
    });
  }
}
