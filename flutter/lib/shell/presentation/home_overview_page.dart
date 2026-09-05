import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';
import '../../device_control/application/device_control_controller.dart';
import '../../energy_monitoring/application/energy_dashboard_controller.dart';
import '../../notifications/application/notification_controller.dart';
import '../../reporting/application/reporting_controller.dart';
import '../../service_management/application/service_controller.dart';
import '../../shared/presentation/widgets/brand_mark.dart';
import '../../shared/presentation/widgets/mascot_panel.dart';
import '../../workplace/application/workplace_controller.dart';

class HomeOverviewPage extends StatelessWidget {
  const HomeOverviewPage({
    super.key,
    required this.userName,
    required this.energy,
    required this.devices,
    required this.workplace,
    required this.notifications,
    required this.reporting,
    required this.service,
    required this.onNavigate,
    required this.onOpenSpaces,
    required this.onOpenService,
    required this.canViewEnergy,
    required this.canManageAlerts,
    required this.canManageSpaces,
    required this.canManageSupport,
  });

  final String userName;
  final EnergyDashboardController energy;
  final DeviceControlController devices;
  final WorkplaceController workplace;
  final NotificationController notifications;
  final ReportingController reporting;
  final ServiceController service;
  final ValueChanged<int> onNavigate;
  final VoidCallback onOpenSpaces;
  final VoidCallback onOpenService;
  final bool canViewEnergy;
  final bool canManageAlerts;
  final bool canManageSpaces;
  final bool canManageSupport;

  @override
  Widget build(BuildContext context) {
    final summary = energy.summary;
    final completed = [
      workplace.locations.isNotEmpty,
      workplace.rooms.isNotEmpty,
      devices.devices.isNotEmpty,
      reporting.goals.isNotEmpty,
      notifications.rules.isNotEmpty,
    ].where((item) => item).length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => Future.wait([
          energy.load(),
          devices.load(),
          workplace.load(),
          notifications.load(),
          reporting.load(),
          service.load(),
        ]),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    const BrandMark(),
                    const Spacer(),
                    if (canManageAlerts)
                      IconButton.filledTonal(
                        tooltip: context.strings.text('alerts'),
                        onPressed: () => onNavigate(3),
                        icon: Badge.count(
                          count: notifications.unreadCount,
                          isLabelVisible: notifications.unreadCount > 0,
                          child: const Icon(Icons.notifications_outlined),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.strings.text('greeting')}, ${_firstName(userName)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.strings.text('operationalCenterDescription'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (completed < 5) ...[
                      const SizedBox(height: 20),
                      _SetupProgress(completed: completed),
                    ],
                  ],
                ),
              ),
            ),
            if (!canViewEnergy)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 300,
                    child: MascotPanel(
                      title: context.strings.text('welcomeEnergyCore'),
                      message: context.strings.text('accessRestricted'),
                    ),
                  ),
                ),
              )
            else if (summary == null && energy.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (summary == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 390,
                    child: MascotPanel(
                      title: context.strings.text('welcomeEnergyCore'),
                      message: context.strings.text('homeEmptyDescription'),
                    ),
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _EnergyHero(
                    watts: summary.currentWatts,
                    kilowattHours: summary.todayKilowattHours,
                    cost: summary.todayEstimatedCost,
                    efficiency: summary.efficiencyScore,
                    onTap: () => onNavigate(1),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 34),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 940
                        ? 3
                        : constraints.crossAxisExtent >= 580
                        ? 2
                        : 1;
                    final cards = [
                      if (canManageSpaces)
                        _OverviewCard(
                          icon: Icons.location_city_outlined,
                          eyebrow: context.strings.text('spaces'),
                          title:
                              '${workplace.locations.length} ${context.strings.text('sites').toLowerCase()}',
                          description:
                              '${workplace.rooms.length} ${context.strings.text('rooms').toLowerCase()}',
                          onTap: onOpenSpaces,
                        ),
                      _OverviewCard(
                        icon: Icons.devices_other_outlined,
                        eyebrow: context.strings.text('devices'),
                        title:
                            '${devices.devices.where((item) => item.isOn).length}/${devices.devices.length} ${context.strings.text('active').toLowerCase()}',
                        description:
                            '${devices.groups.length} ${context.strings.text('groups').toLowerCase()} · ${devices.routines.length} ${context.strings.text('routines').toLowerCase()}',
                        onTap: () => onNavigate(2),
                      ),
                      if (canViewEnergy)
                        _OverviewCard(
                          icon: Icons.flag_outlined,
                          eyebrow: context.strings.text('goals'),
                          title:
                              '${reporting.goals.where((item) => item.status == 'ACTIVE').length} ${context.strings.text('active').toLowerCase()}',
                          description:
                              '${reporting.reports.length} ${context.strings.text('reports').toLowerCase()}',
                          onTap: () => onNavigate(1),
                        ),
                      if (canManageAlerts)
                        _OverviewCard(
                          icon: Icons.notifications_active_outlined,
                          eyebrow: context.strings.text('alerts'),
                          title:
                              '${notifications.unreadCount} ${context.strings.text('unread').toLowerCase()}',
                          description:
                              '${notifications.rules.where((item) => item.enabled).length} ${context.strings.text('activeRules').toLowerCase()}',
                          onTap: () => onNavigate(3),
                        ),
                      _OverviewCard(
                        icon: Icons.tune_rounded,
                        eyebrow: context.strings.text('modes'),
                        title:
                            devices.modes
                                .where((item) => item.isActive)
                                .firstOrNull
                                ?.name ??
                            context.strings.text('noActiveMode'),
                        description:
                            '${devices.modes.length} ${context.strings.text('available').toLowerCase()}',
                        onTap: () => onNavigate(2),
                      ),
                      if (canManageSupport)
                        _OverviewCard(
                          icon: Icons.support_agent_outlined,
                          eyebrow: context.strings.text('service'),
                          title:
                              '${service.supportTickets.where((item) => item.status == 'OPEN').length} ${context.strings.text('open').toLowerCase()}',
                          description:
                              '${service.maintenanceTickets.where((item) => item.status != 'COMPLETED').length} ${context.strings.text('maintenance').toLowerCase()}',
                          onTap: onOpenService,
                        ),
                    ];
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 164,
                      ),
                      delegate: SliverChildListDelegate(cards),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetupProgress extends StatelessWidget {
  const _SetupProgress({required this.completed});
  final int completed;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.strings.text('setupGuide'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$completed/5',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completed / 5,
            minHeight: 9,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    ),
  );
}

class _EnergyHero extends StatelessWidget {
  const _EnergyHero({
    required this.watts,
    required this.kilowattHours,
    required this.cost,
    required this.efficiency,
    required this.onTap,
  });
  final double watts;
  final double kilowattHours;
  final double cost;
  final int efficiency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: const Color(0xFF0D2A18),
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF12371F),
                const Color(0xFF0A1710),
                scheme.secondary.withValues(alpha: 0.18),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.strings.text('live'),
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${watts.toStringAsFixed(0)} W',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 5),
              Text(
                context.strings.text('currentPower'),
                style: const TextStyle(color: Color(0xFFB7C6BA)),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 20,
                runSpacing: 12,
                children: [
                  _heroMetric(
                    '${kilowattHours.toStringAsFixed(2)} kWh',
                    context.strings.text('todayEnergy'),
                  ),
                  _heroMetric(
                    'S/ ${cost.toStringAsFixed(2)}',
                    context.strings.text('todayCost'),
                  ),
                  _heroMetric(
                    '$efficiency%',
                    context.strings.text('efficiency'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroMetric(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 17,
        ),
      ),
      Text(
        label,
        style: const TextStyle(color: Color(0xFF9FB0A3), fontSize: 12),
      ),
    ],
  );
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const Spacer(),
                const Icon(Icons.arrow_outward_rounded, size: 19),
              ],
            ),
            const Spacer(),
            Text(
              eyebrow.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 3),
            Text(description, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ),
  );
}

String _firstName(String value) =>
    value.trim().split(RegExp(r'\s+')).firstOrNull ?? value;
