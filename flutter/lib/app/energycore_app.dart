import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../billing/application/billing_controller.dart';
import '../billing/infrastructure/billing_api_repository.dart';
import '../billing/presentation/billing_page.dart';
import '../device_control/application/device_control_controller.dart';
import '../device_control/infrastructure/device_control_api_repository.dart';
import '../energy_monitoring/application/energy_dashboard_controller.dart';
import '../energy_monitoring/infrastructure/energy_api_repository.dart';
import '../iam/application/account_controller.dart';
import '../iam/application/auth_controller.dart';
import '../iam/infrastructure/account_api_repository.dart';
import '../iam/infrastructure/auth_api_repository.dart';
import '../iam/presentation/auth_page.dart';
import '../notifications/application/notification_controller.dart';
import '../notifications/infrastructure/notification_api_repository.dart';
import '../reporting/application/reporting_controller.dart';
import '../reporting/infrastructure/reporting_api_repository.dart';
import '../service_management/application/service_controller.dart';
import '../service_management/infrastructure/service_api_repository.dart';
import '../shared/infrastructure/network/api_client.dart';
import '../shared/infrastructure/storage/token_store.dart';
import '../shared/application/ui_preferences_controller.dart';
import '../shared/infrastructure/ui_preferences_api_repository.dart';
import '../shared/presentation/widgets/brand_mark.dart';
import '../shell/presentation/main_shell.dart';
import '../workplace/application/workplace_controller.dart';
import '../workplace/infrastructure/workplace_api_repository.dart';
import 'localization/app_strings.dart';
import 'theme/energycore_theme.dart';

class EnergyCoreApp extends StatefulWidget {
  const EnergyCoreApp({super.key});

  @override
  State<EnergyCoreApp> createState() => _EnergyCoreAppState();
}

class _EnergyCoreAppState extends State<EnergyCoreApp> {
  late final TokenStore _tokenStore;
  late final AuthController _authController;
  late final EnergyDashboardController _energyController;
  late final DeviceControlController _deviceController;
  late final WorkplaceController _workplaceController;
  late final NotificationController _notificationController;
  late final ReportingController _reportingController;
  late final ServiceController _serviceController;
  late final BillingController _billingController;
  late final AccountController _accountController;
  late final UiPreferencesController _preferencesController;

  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;
  bool _dataInitialized = false;
  bool _billingInitialized = false;

  @override
  void initState() {
    super.initState();
    _tokenStore = SecureTokenStore();
    final api = ApiClient(_tokenStore);
    _authController = AuthController(AuthApiRepository(api), _tokenStore)
      ..addListener(_handleAuthChange);
    _energyController = EnergyDashboardController(EnergyApiRepository(api));
    _deviceController = DeviceControlController(
      DeviceControlApiRepository(api),
    );
    _workplaceController = WorkplaceController(WorkplaceApiRepository(api));
    _notificationController = NotificationController(
      NotificationApiRepository(api),
    );
    _reportingController = ReportingController(ReportingApiRepository(api));
    _serviceController = ServiceController(ServiceApiRepository(api));
    _billingController = BillingController(BillingApiRepository(api));
    _billingController.addListener(_handleBillingChange);
    _accountController = AccountController(AccountApiRepository(api));
    _preferencesController = UiPreferencesController(
      UiPreferencesApiRepository(api),
    )..addListener(_handlePreferencesChange);
    _authController.initialize();
  }

  void _handleAuthChange() {
    if (_authController.status == AuthStatus.authenticated &&
        !_billingInitialized) {
      _billingInitialized = true;
      _billingController.load();
      _preferencesController.load();
    } else if (_authController.status == AuthStatus.unauthenticated) {
      _dataInitialized = false;
      _billingInitialized = false;
    }
  }

  void _handleBillingChange() {
    if (_authController.status != AuthStatus.authenticated ||
        _billingController.subscription?.active != true ||
        _dataInitialized) {
      return;
    }
    _dataInitialized = true;
    _energyController.load();
    _deviceController.load();
    _workplaceController.load();
    _notificationController.load();
    _reportingController.load();
    _serviceController.load();
  }

  void _handlePreferencesChange() {
    final language = _preferencesController.language;
    final theme = _preferencesController.theme;
    final nextLocale = language == null ? _locale : Locale(language);
    final nextTheme = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => _themeMode,
    };
    if (nextLocale == _locale && nextTheme == _themeMode) return;
    setState(() {
      _locale = nextLocale;
      _themeMode = nextTheme;
    });
  }

  void _changeLocale(Locale? locale) {
    setState(() => _locale = locale);
    if (locale != null && _authController.status == AuthStatus.authenticated) {
      _preferencesController.save(
        language: locale.languageCode,
        theme: _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    }
  }

  void _changeTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
    if (_authController.status == AuthStatus.authenticated) {
      final brightness = MediaQuery.platformBrightnessOf(context);
      final remoteTheme = mode == ThemeMode.system
          ? brightness == Brightness.dark
                ? 'dark'
                : 'light'
          : mode == ThemeMode.dark
          ? 'dark'
          : 'light';
      _preferencesController.save(
        language: (_locale ?? const Locale('es')).languageCode,
        theme: remoteTheme,
      );
    }
  }

  @override
  void dispose() {
    _authController
      ..removeListener(_handleAuthChange)
      ..dispose();
    _energyController.dispose();
    _deviceController.dispose();
    _workplaceController.dispose();
    _notificationController.dispose();
    _reportingController.dispose();
    _serviceController.dispose();
    _billingController
      ..removeListener(_handleBillingChange)
      ..dispose();
    _accountController.dispose();
    _preferencesController
      ..removeListener(_handlePreferencesChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EnergyCore',
      theme: EnergyCoreTheme.light,
      darkTheme: EnergyCoreTheme.dark,
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AnimatedBuilder(
        animation: Listenable.merge([
          _authController,
          _billingController,
          _preferencesController,
        ]),
        builder: (context, _) {
          return switch (_authController.status) {
            AuthStatus.checking => const _StartupPage(),
            AuthStatus.authenticated
                when _billingController.isLoading &&
                    _billingController.plans.isEmpty =>
              const _StartupPage(),
            AuthStatus.authenticated
                when _billingController.subscription?.active != true =>
              BillingPage(
                controller: _billingController,
                subscriptionRequired: true,
                onSignOut: _authController.signOut,
              ),
            AuthStatus.authenticated => MainShell(
              user: _authController.user!,
              authController: _authController,
              energyController: _energyController,
              deviceController: _deviceController,
              workplaceController: _workplaceController,
              notificationController: _notificationController,
              reportingController: _reportingController,
              serviceController: _serviceController,
              billingController: _billingController,
              accountController: _accountController,
              locale: _locale,
              themeMode: _themeMode,
              onLocaleChanged: _changeLocale,
              onThemeChanged: _changeTheme,
            ),
            AuthStatus.unauthenticated || AuthStatus.authenticating => AuthPage(
              controller: _authController,
              locale: _locale,
              onLocaleChanged: _changeLocale,
            ),
          };
        },
      ),
    );
  }
}

class _StartupPage extends StatelessWidget {
  const _StartupPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(),
            SizedBox(height: 26),
            SizedBox.square(
              dimension: 26,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
