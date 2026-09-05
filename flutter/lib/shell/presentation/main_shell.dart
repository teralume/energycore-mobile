import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';
import '../../billing/application/billing_controller.dart';
import '../../billing/presentation/billing_page.dart';
import '../../device_control/application/device_control_controller.dart';
import '../../device_control/presentation/device_control_page.dart';
import '../../energy_monitoring/application/energy_dashboard_controller.dart';
import '../../iam/application/account_controller.dart';
import '../../iam/application/auth_controller.dart';
import '../../iam/domain/auth_session.dart';
import '../../iam/presentation/account_page.dart';
import '../../notifications/application/notification_controller.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../reporting/application/reporting_controller.dart';
import '../../reporting/presentation/energy_hub_page.dart';
import '../../service_management/application/service_controller.dart';
import '../../service_management/presentation/service_page.dart';
import '../../shared/presentation/widgets/brand_mark.dart';
import '../../shared/presentation/widgets/offline_banner.dart';
import '../../workplace/application/workplace_controller.dart';
import '../../workplace/presentation/workplace_page.dart';
import 'home_overview_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.user,
    required this.authController,
    required this.energyController,
    required this.deviceController,
    required this.workplaceController,
    required this.notificationController,
    required this.reportingController,
    required this.serviceController,
    required this.billingController,
    required this.accountController,
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeChanged,
  });

  final AuthenticatedUser user;
  final AuthController authController;
  final EnergyDashboardController energyController;
  final DeviceControlController deviceController;
  final WorkplaceController workplaceController;
  final NotificationController notificationController;
  final ReportingController reportingController;
  final ServiceController serviceController;
  final BillingController billingController;
  final AccountController accountController;
  final Locale? locale;
  final ThemeMode themeMode;
  final ValueChanged<Locale?> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late final Listenable _allData;

  @override
  void initState() {
    super.initState();
    _allData = Listenable.merge([
      widget.energyController,
      widget.deviceController,
      widget.workplaceController,
      widget.notificationController,
      widget.reportingController,
      widget.serviceController,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final canViewEnergy = widget.user.hasPermission('VIEW_ENERGY');
    final canManageAlerts = widget.user.hasPermission('MANAGE_ALERTS');
    final destinations = [
      _Destination(
        Icons.home_outlined,
        Icons.home_rounded,
        strings.text('home'),
      ),
      _Destination(
        Icons.bolt_outlined,
        Icons.bolt_rounded,
        strings.text('energy'),
      ),
      _Destination(
        Icons.devices_other_outlined,
        Icons.devices_other_rounded,
        strings.text('devices'),
      ),
      _Destination(
        Icons.notifications_outlined,
        Icons.notifications_rounded,
        strings.text('alerts'),
      ),
      _Destination(
        Icons.grid_view_outlined,
        Icons.grid_view_rounded,
        strings.text('more'),
      ),
    ];

    return AnimatedBuilder(
      animation: _allData,
      builder: (context, _) {
        final pages = [
          HomeOverviewPage(
            userName: widget.user.fullName,
            energy: widget.energyController,
            devices: widget.deviceController,
            workplace: widget.workplaceController,
            notifications: widget.notificationController,
            reporting: widget.reportingController,
            service: widget.serviceController,
            onNavigate: (index) => setState(() => _selectedIndex = index),
            onOpenSpaces: _openSpaces,
            onOpenService: _openService,
            canViewEnergy: canViewEnergy,
            canManageAlerts: canManageAlerts,
            canManageSpaces: widget.user.hasPermission('MANAGE_SPACES'),
            canManageSupport: widget.user.hasPermission('MANAGE_SUPPORT'),
          ),
          canViewEnergy
              ? EnergyHubPage(
                  dashboardController: widget.energyController,
                  reportingController: widget.reportingController,
                  userName: widget.user.fullName,
                  canAccessHistory:
                      widget.billingController.canAccessEnergyHistory,
                  canExport: widget.billingController.canExportReports,
                )
              : const _AccessDeniedPage(),
          DeviceControlPage(
            controller: widget.deviceController,
            locations: widget.workplaceController.locations,
            rooms: widget.workplaceController.rooms,
            assignments: widget.workplaceController.assignments,
            goals: widget.reportingController.goals,
            ruleProfiles: widget.notificationController.profiles,
            notificationPreferenceId:
                widget.notificationController.preferences?.id,
            canCreateDevice: widget.billingController.canCreateDevice(
              widget.deviceController.devices.length,
            ),
            canCreateRoutine: widget.billingController.canCreateRoutine(
              widget.deviceController.routines.length,
            ),
          ),
          canManageAlerts
              ? NotificationsPage(
                  controller: widget.notificationController,
                  canCreateAlert: widget.billingController.canCreateAlert(
                    widget.notificationController.alerts.length,
                  ),
                )
              : const _AccessDeniedPage(),
          _MorePage(
            user: widget.user,
            locale: widget.locale,
            themeMode: widget.themeMode,
            onLocaleChanged: widget.onLocaleChanged,
            onThemeChanged: widget.onThemeChanged,
            onOpenSpaces: _openSpaces,
            onOpenService: _openService,
            onOpenBilling: _openBilling,
            onOpenAccount: _openAccount,
            onSignOut: _signOut,
            canManageSpaces: widget.user.hasPermission('MANAGE_SPACES'),
            canManageSupport: widget.user.hasPermission('MANAGE_SUPPORT'),
            canManageBilling: widget.user.hasPermission('MANAGE_BILLING'),
          ),
        ];
        final offline = [
          widget.energyController.failure,
          widget.deviceController.failure,
          widget.workplaceController.failure,
          widget.notificationController.failure,
          widget.reportingController.failure,
          widget.serviceController.failure,
        ].any((failure) => failure?.isOffline ?? false);

        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 880;
              final content = Column(
                children: [
                  OfflineBanner(visible: offline, onRetry: _retryAll),
                  Expanded(
                    child: IndexedStack(index: _selectedIndex, children: pages),
                  ),
                ],
              );

              if (!wide) return content;
              return Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (value) =>
                        setState(() => _selectedIndex = value),
                    labelType: NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: BrandMark(compact: true),
                    ),
                    destinations: destinations
                        .map(
                          (item) => NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: Text(item.label),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              );
            },
          ),
          bottomNavigationBar: MediaQuery.sizeOf(context).width < 880
              ? NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) =>
                      setState(() => _selectedIndex = value),
                  destinations: destinations
                      .map(
                        (item) => NavigationDestination(
                          icon: item.label == strings.text('alerts')
                              ? Badge.count(
                                  count:
                                      widget.notificationController.unreadCount,
                                  isLabelVisible:
                                      widget
                                          .notificationController
                                          .unreadCount >
                                      0,
                                  child: Icon(item.icon),
                                )
                              : Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: item.label,
                        ),
                      )
                      .toList(growable: false),
                )
              : null,
        );
      },
    );
  }

  Future<void> _retryAll() => Future.wait([
    widget.energyController.load(),
    widget.deviceController.load(),
    widget.workplaceController.load(),
    widget.notificationController.load(),
    widget.reportingController.load(),
    widget.serviceController.load(),
  ]);

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openSpaces() => _open(
    widget.user.hasPermission('MANAGE_SPACES')
        ? WorkplacePage(
            controller: widget.workplaceController,
            devices: widget.deviceController.devices,
            canCreateMultipleLocations:
                widget.billingController.canUseMultipleLocations,
          )
        : const _AccessDeniedPage(),
  );

  void _openService() => _open(
    widget.user.hasPermission('MANAGE_SUPPORT')
        ? ServicePage(
            controller: widget.serviceController,
            devices: widget.deviceController.devices,
          )
        : const _AccessDeniedPage(),
  );

  void _openBilling() => _open(
    widget.user.hasPermission('MANAGE_BILLING')
        ? BillingPage(controller: widget.billingController)
        : const _AccessDeniedPage(),
  );

  void _openAccount() => _open(
    AccountPage(
      controller: widget.accountController,
      onAccountDeleted: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _signOut();
      },
    ),
  );

  void _signOut() {
    widget.energyController.reset();
    widget.authController.signOut();
  }
}

class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _MorePage extends StatelessWidget {
  const _MorePage({
    required this.user,
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeChanged,
    required this.onOpenSpaces,
    required this.onOpenService,
    required this.onOpenBilling,
    required this.onOpenAccount,
    required this.onSignOut,
    required this.canManageSpaces,
    required this.canManageSupport,
    required this.canManageBilling,
  });

  final AuthenticatedUser user;
  final Locale? locale;
  final ThemeMode themeMode;
  final ValueChanged<Locale?> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onOpenSpaces;
  final VoidCallback onOpenService;
  final VoidCallback onOpenBilling;
  final VoidCallback onOpenAccount;
  final VoidCallback onSignOut;
  final bool canManageSpaces;
  final bool canManageSupport;
  final bool canManageBilling;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final activeLocale = locale ?? Localizations.localeOf(context);
    final entries = <_MoreEntry>[
      if (canManageSpaces)
        _MoreEntry(
          Icons.location_city_outlined,
          strings.text('spaces'),
          strings.text('spacesDescription'),
          onOpenSpaces,
        ),
      if (canManageSupport)
        _MoreEntry(
          Icons.support_agent_outlined,
          strings.text('service'),
          strings.text('serviceDescription'),
          onOpenService,
        ),
      if (canManageBilling)
        _MoreEntry(
          Icons.workspace_premium_outlined,
          strings.text('billing'),
          strings.text('billingDescription'),
          onOpenBilling,
        ),
      _MoreEntry(
        Icons.manage_accounts_outlined,
        strings.text('account'),
        strings.text('accountDescription'),
        onOpenAccount,
      ),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
        children: [
          Row(
            children: [
              const BrandMark(),
              const Spacer(),
              StatusChip(label: user.accessProfileName ?? user.status),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            strings.text('more'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(strings.text('moreDescription')),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 2 : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: entries
                    .map(
                      (entry) => SizedBox(
                        width: width,
                        child: _MoreCard(entry: entry),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: const Icon(Icons.language_rounded),
                  title: Text(strings.text('language')),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: activeLocale.languageCode,
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'pt', child: Text('Português')),
                      ],
                      onChanged: (value) {
                        if (value != null) onLocaleChanged(Locale(value));
                      },
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: const Icon(Icons.contrast_rounded),
                  title: Text(strings.text('appearance')),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<ThemeMode>(
                      value: themeMode,
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(strings.text('system')),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(strings.text('light')),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(strings.text('dark')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) onThemeChanged(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: Text(strings.text('signOut')),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: const Icon(Icons.verified_user_outlined, size: 17),
    label: Text(label),
  );
}

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.strings.text('access'))),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              context.strings.text('accessRestricted'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ),
  );
}

class _MoreEntry {
  const _MoreEntry(this.icon, this.title, this.description, this.onTap);
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
}

class _MoreCard extends StatelessWidget {
  const _MoreCard({required this.entry});
  final _MoreEntry entry;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: entry.onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              entry.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
