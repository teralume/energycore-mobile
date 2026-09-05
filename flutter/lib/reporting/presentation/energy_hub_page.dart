import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization/app_strings.dart';
import '../../energy_monitoring/application/energy_dashboard_controller.dart';
import '../../energy_monitoring/presentation/energy_dashboard_page.dart';
import '../../shared/presentation/widgets/module_widgets.dart';
import '../application/reporting_controller.dart';
import '../domain/reporting_models.dart';

class EnergyHubPage extends StatefulWidget {
  const EnergyHubPage({
    super.key,
    required this.dashboardController,
    required this.reportingController,
    required this.userName,
    required this.canAccessHistory,
    required this.canExport,
  });

  final EnergyDashboardController dashboardController;
  final ReportingController reportingController;
  final String userName;
  final bool canAccessHistory;
  final bool canExport;

  @override
  State<EnergyHubPage> createState() => _EnergyHubPageState();
}

class _EnergyHubPageState extends State<EnergyHubPage> {
  @override
  void initState() {
    super.initState();
    if (!widget.reportingController.isLoading &&
        widget.reportingController.readings.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.reportingController.load(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.reportingController,
      builder: (context, _) => DefaultTabController(
        length: 4,
        child: SafeArea(
          child: Column(
            children: [
              ModuleHeader(
                eyebrow: context.strings.text('energy'),
                title: context.strings.text('energyCenter'),
                description: context.strings.text('energyCenterDescription'),
              ),
              TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: context.strings.text('consumption')),
                  Tab(text: context.strings.text('history')),
                  Tab(text: context.strings.text('reports')),
                  Tab(text: context.strings.text('goals')),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    EnergyDashboardPage(
                      controller: widget.dashboardController,
                      userName: widget.userName,
                      detailsOnly: true,
                      canExport: widget.canExport,
                    ),
                    widget.canAccessHistory
                        ? _HistoryTab(
                            controller: widget.reportingController,
                            canExport: widget.canExport,
                          )
                        : const _PlanRestricted(),
                    _ReportsTab(
                      controller: widget.reportingController,
                      canExport: widget.canExport,
                    ),
                    _GoalsTab(controller: widget.reportingController),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTab extends StatefulWidget {
  const _HistoryTab({required this.controller, required this.canExport});
  final ReportingController controller;
  final bool canExport;

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  String query = '';
  String status = 'ALL';
  String sort = 'NEWEST';
  double? minWatts;
  double? maxWatts;
  int page = 0;
  static const pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final readings = widget.controller.readings
        .where((item) {
          final matchesQuery = item.deviceName.toLowerCase().contains(
            query.toLowerCase(),
          );
          final matchesStatus = status == 'ALL' || item.status == status;
          final matchesMin = minWatts == null || item.watts >= minWatts!;
          final matchesMax = maxWatts == null || item.watts <= maxWatts!;
          return matchesQuery && matchesStatus && matchesMin && matchesMax;
        })
        .toList(growable: false);
    readings.sort((a, b) {
      if (sort == 'POWER_DESC') return b.watts.compareTo(a.watts);
      if (sort == 'POWER_ASC') return a.watts.compareTo(b.watts);
      final left = a.recordedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.recordedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return sort == 'OLDEST' ? left.compareTo(right) : right.compareTo(left);
    });
    final lastPage = readings.isEmpty ? 0 : (readings.length - 1) ~/ pageSize;
    if (page > lastPage) page = lastPage;
    final visible = readings.skip(page * pageSize).take(pageSize).toList();
    return ModuleBody(
      loading: widget.controller.isLoading,
      failure: widget.controller.failure,
      empty: widget.controller.readings.isEmpty,
      onRetry: widget.controller.load,
      emptyTitle: context.strings.text('noReadings'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() {
                    query = value;
                    page = 0;
                  }),
                  decoration: InputDecoration(
                    hintText: context.strings.text('searchDevice'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: context.strings.text('dateRange'),
                      onPressed: () => _pickDateRange(context),
                      icon: const Icon(Icons.date_range_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterMenu(
                        context,
                        icon: Icons.monitor_heart_outlined,
                        label: status == 'ALL'
                            ? context.strings.text('all')
                            : status,
                        values: const ['ALL', 'NORMAL', 'HIGH'],
                        onSelected: (value) => setState(() {
                          status = value;
                          page = 0;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _filterMenu(
                        context,
                        icon: Icons.swap_vert_rounded,
                        label: context.strings.text(sort.toLowerCase()),
                        values: const [
                          'NEWEST',
                          'OLDEST',
                          'POWER_DESC',
                          'POWER_ASC',
                        ],
                        onSelected: (value) => setState(() => sort = value),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.tune_rounded, size: 18),
                        label: Text(context.strings.text('powerRange')),
                        onPressed: () => _powerRange(context),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.timer_outlined, size: 18),
                        label: Text('${widget.controller.samplingSeconds}s'),
                        onPressed: () => _sampling(context),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.download_outlined, size: 18),
                        label: Text(context.strings.text('export')),
                        onPressed: widget.canExport
                            ? () => _copyReadings(context, readings)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ResponsiveRecordList(
              children: visible
                  .map(
                    (reading) => RecordCard(
                      icon: Icons.monitor_heart_outlined,
                      title: reading.deviceName,
                      subtitle: reading.recordedAt == null
                          ? context.strings.text('unknownDate')
                          : _dateTime(reading.recordedAt!),
                      trailing: StatusPill(
                        label: reading.status,
                        positive: reading.status == 'NORMAL',
                      ),
                      details: [
                        '${reading.watts.toStringAsFixed(0)} W',
                        '${reading.kilowattHours.toStringAsFixed(3)} kWh',
                        'S/ ${reading.estimatedCost.toStringAsFixed(2)}',
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          if (readings.length > pageSize)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: page > 0 ? () => setState(() => page--) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text('${page + 1} / ${lastPage + 1}'),
                  IconButton(
                    onPressed: page < lastPage
                        ? () => setState(() => page++)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _copyReadings(
    BuildContext context,
    List<EnergyReading> readings,
  ) async {
    final rows = <String>[
      'id,deviceId,deviceName,watts,kilowattHours,estimatedCost,recordedAt,status',
      ...readings.map(
        (item) => [
          item.id,
          item.deviceId,
          '"${item.deviceName.replaceAll('"', '""')}"',
          item.watts,
          item.kilowattHours,
          item.estimatedCost,
          item.recordedAt?.toIso8601String() ?? '',
          item.status,
        ].join(','),
      ),
    ];
    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.strings.text('copiedToClipboard'))),
    );
  }

  Widget _filterMenu(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<String> values,
    required ValueChanged<String> onSelected,
  }) => PopupMenuButton<String>(
    onSelected: onSelected,
    itemBuilder: (context) => values
        .map(
          (value) => PopupMenuItem(
            value: value,
            child: Text(context.strings.text(value.toLowerCase())),
          ),
        )
        .toList(growable: false),
    child: Chip(avatar: Icon(icon, size: 18), label: Text(label)),
  );

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (range == null || !context.mounted) return;
    await runAction(
      context,
      widget.controller.filterByDate(range.start, range.end),
    );
  }

  Future<void> _powerRange(BuildContext context) async {
    final min = TextEditingController(text: minWatts?.toString());
    final max = TextEditingController(text: maxWatts?.toString());
    final applied = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.strings.text('powerRange')),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: min,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.strings.text('minimum'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: max,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.strings.text('maximum'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.strings.text('apply')),
          ),
        ],
      ),
    );
    if (applied == true) {
      setState(() {
        minWatts = double.tryParse(min.text);
        maxWatts = double.tryParse(max.text);
        page = 0;
      });
    }
    min.dispose();
    max.dispose();
  }

  Future<void> _sampling(BuildContext context) async {
    final value = TextEditingController(
      text: widget.controller.samplingSeconds.toString(),
    );
    final applied = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.strings.text('samplingInterval')),
        content: TextField(
          controller: value,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.strings.text('seconds'),
            helperText: '5–3600',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final seconds = int.tryParse(value.text) ?? 0;
              Navigator.pop(context, seconds >= 5 && seconds <= 3600);
            },
            child: Text(context.strings.text('save')),
          ),
        ],
      ),
    );
    if (applied == true && context.mounted) {
      await runAction(
        context,
        widget.controller.saveSamplingSeconds(int.parse(value.text)),
      );
    }
    value.dispose();
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({required this.controller, required this.canExport});
  final ReportingController controller;
  final bool canExport;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ModuleBody(
        loading: controller.isLoading,
        failure: controller.failure,
        empty: controller.reports.isEmpty,
        onRetry: controller.load,
        emptyTitle: context.strings.text('noReports'),
        child: ResponsiveRecordList(
          children: controller.reports
              .map(
                (report) => RecordCard(
                  icon: Icons.analytics_outlined,
                  title: '${context.strings.text('report')} #${report.id}',
                  subtitle:
                      '${_date(report.startDate)} – ${_date(report.endDate)}',
                  details: [
                    '${context.strings.text('total')}: ${report.totalWatts.toStringAsFixed(0)} W',
                    '${context.strings.text('average')}: ${report.averageWatts.toStringAsFixed(0)} W',
                    '${context.strings.text('peak')}: ${report.highestWatts.toStringAsFixed(0)} W',
                  ],
                  actions: [
                    FilledButton.tonalIcon(
                      onPressed: () => _showReport(context, report),
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(context.strings.text('details')),
                    ),
                    TextButton.icon(
                      onPressed: canExport
                          ? () => _copyReport(context, report)
                          : null,
                      icon: const Icon(Icons.download_outlined),
                      label: Text(context.strings.text('export')),
                    ),
                    TextButton.icon(
                      onPressed: controller.isMutating
                          ? null
                          : () => runAction(
                              context,
                              controller.deleteReport(report.id),
                            ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(context.strings.text('delete')),
                    ),
                  ],
                ),
              )
              .followedBy(
                controller.events
                    .take(6)
                    .map(
                      (event) => RecordCard(
                        icon: Icons.history_toggle_off_rounded,
                        title: event.summary,
                        subtitle: event.detail ?? event.eventName,
                        details: [
                          event.sourceContext,
                          _dateTimeOrDash(event.occurredOn),
                        ],
                      ),
                    ),
              )
              .toList(growable: false),
        ),
      ),
      Positioned(
        right: 20,
        bottom: 20,
        child: FloatingActionButton.extended(
          heroTag: 'generate-report',
          onPressed: controller.isMutating ? null : () => _generate(context),
          icon: const Icon(Icons.auto_graph_rounded),
          label: Text(context.strings.text('generateReport')),
        ),
      ),
    ],
  );

  Future<void> _generate(BuildContext context) async {
    final now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day - 7);
    var end = now;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.strings.text('generateReport')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.first_page_rounded),
                title: Text(context.strings.text('startDate')),
                trailing: Text(_date(start)),
                onTap: () async {
                  final value = await showDatePicker(
                    context: context,
                    firstDate: DateTime(now.year - 2),
                    lastDate: now,
                    initialDate: start,
                  );
                  if (value != null) setState(() => start = value);
                },
              ),
              ListTile(
                leading: const Icon(Icons.last_page_rounded),
                title: Text(context.strings.text('endDate')),
                trailing: Text(_date(end)),
                onTap: () async {
                  final value = await showDatePicker(
                    context: context,
                    firstDate: start,
                    lastDate: now,
                    initialDate: end,
                  );
                  if (value != null) setState(() => end = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.strings.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, !end.isBefore(start)),
              child: Text(context.strings.text('generate')),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      final success = await controller.generateReport(start, end);
      if (context.mounted) showActionResult(context, success);
    }
  }

  Future<void> _showReport(
    BuildContext context,
    ConsumptionReport report,
  ) => showDialog<void>(
    context: context,
    builder: (context) {
      final readings = controller.readings
          .where((reading) {
            final at = reading.recordedAt;
            if (at == null) return false;
            final start = report.startDate;
            final end = report.endDate;
            return (start == null || !at.isBefore(start)) &&
                (end == null || !at.isAfter(end.add(const Duration(days: 1))));
          })
          .toList(growable: false);
      final byDevice = <String, double>{};
      for (final reading in readings) {
        byDevice.update(
          reading.deviceName,
          (value) => value + reading.kilowattHours,
          ifAbsent: () => reading.kilowattHours,
        );
      }
      final ranking = byDevice.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return AlertDialog(
        title: Text('${context.strings.text('report')} #${report.id}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_date(report.startDate)} – ${_date(report.endDate)}'),
                const SizedBox(height: 16),
                _metric(
                  context,
                  context.strings.text('total'),
                  report.totalWatts,
                ),
                _metric(
                  context,
                  context.strings.text('average'),
                  report.averageWatts,
                ),
                _metric(
                  context,
                  context.strings.text('peak'),
                  report.highestWatts,
                ),
                const SizedBox(height: 18),
                Text(
                  context.strings.text('deviceBreakdown'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (ranking.isEmpty)
                  Text(context.strings.text('noReadings'))
                else
                  ...ranking
                      .take(8)
                      .map(
                        (entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.electrical_services_outlined,
                          ),
                          title: Text(entry.key),
                          trailing: Text(
                            '${entry.value.toStringAsFixed(3)} kWh',
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.strings.text('close')),
          ),
        ],
      );
    },
  );

  Widget _metric(BuildContext context, String label, double watts) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          '${watts.toStringAsFixed(1)} W',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  Future<void> _copyReport(
    BuildContext context,
    ConsumptionReport report,
  ) async {
    final csv =
        'id,startDate,endDate,totalWatts,averageWatts,highestWatts\n'
        '${report.id},${_date(report.startDate)},${_date(report.endDate)},'
        '${report.totalWatts},${report.averageWatts},${report.highestWatts}';
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    showActionResult(context, true, context.strings.text('copiedToClipboard'));
  }
}

class _PlanRestricted extends StatelessWidget {
  const _PlanRestricted();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            context.strings.text('upgradePlanFeature'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    ),
  );
}

class _GoalsTab extends StatelessWidget {
  const _GoalsTab({required this.controller});
  final ReportingController controller;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ModuleBody(
        loading: controller.isLoading,
        failure: controller.failure,
        empty: controller.goals.isEmpty,
        onRetry: controller.load,
        emptyTitle: context.strings.text('noGoals'),
        child: ResponsiveRecordList(
          children: controller.goals
              .map(
                (goal) => _GoalCard(
                  goal: goal,
                  controller: controller,
                  onEdit: () => _create(context, goal),
                ),
              )
              .toList(growable: false),
        ),
      ),
      Positioned(
        right: 20,
        bottom: 20,
        child: FloatingActionButton.extended(
          heroTag: 'create-goal',
          onPressed: controller.isMutating
              ? null
              : () => _create(context, null),
          icon: const Icon(Icons.flag_outlined),
          label: Text(context.strings.text('newGoal')),
        ),
      ),
    ],
  );

  Future<void> _create(BuildContext context, EnergyGoal? goal) async {
    final title = TextEditingController(text: goal?.title);
    final target = TextEditingController(
      text: goal?.targetKilowattHours.toString() ?? '100',
    );
    final current = TextEditingController(
      text: goal?.currentKilowattHours.toString() ?? '0',
    );
    var status = goal?.status ?? 'ACTIVE';
    var deadline =
        goal?.deadline ?? DateTime.now().add(const Duration(days: 30));
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            context.strings.text(goal == null ? 'newGoal' : 'editGoal'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: InputDecoration(
                  labelText: context.strings.text('name'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: target,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.strings.text('targetKwh'),
                ),
              ),
              if (goal != null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: current,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.strings.text('currentKwh'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: context.strings.text('status'),
                  ),
                  items: const ['ACTIVE', 'COMPLETED', 'FAILED']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setState(() => status = value ?? status),
                ),
              ],
              const SizedBox(height: 12),
              ListTile(
                title: Text(context.strings.text('deadline')),
                trailing: Text(_date(deadline)),
                onTap: () async {
                  final now = DateTime.now();
                  final value = await showDatePicker(
                    context: context,
                    firstDate: now,
                    lastDate: DateTime(now.year + 5),
                    initialDate: deadline,
                  );
                  if (value != null) setState(() => deadline = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.strings.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                title.text.trim().isNotEmpty &&
                    double.tryParse(target.text) != null,
              ),
              child: Text(context.strings.text('save')),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      final action = goal == null
          ? controller.createGoal(
              title.text.trim(),
              double.parse(target.text),
              deadline,
            )
          : controller.updateGoal(
              goal,
              title.text.trim(),
              double.parse(target.text),
              double.tryParse(current.text) ?? 0,
              deadline,
              status,
            );
      await runAction(context, action);
    }
    title.dispose();
    target.dispose();
    current.dispose();
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.controller,
    required this.onEdit,
  });
  final EnergyGoal goal;
  final ReportingController controller;
  final VoidCallback onEdit;

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
                  goal.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(label: goal.status, positive: goal.status == 'ACTIVE'),
            ],
          ),
          const SizedBox(height: 10),
          Text(goal.scopeName),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: goal.progress,
            minHeight: 9,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          Text(
            '${goal.currentKilowattHours.toStringAsFixed(1)} / ${goal.targetKilowattHours.toStringAsFixed(1)} kWh · ${(goal.progress * 100).toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 18),
              const SizedBox(width: 7),
              Expanded(child: Text(_date(goal.deadline))),
              IconButton(
                onPressed: controller.isMutating ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: controller.isMutating
                    ? null
                    : () => runAction(context, controller.deleteGoal(goal.id)),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

String _date(DateTime? value) => value == null
    ? '—'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dateTime(DateTime value) =>
    '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _dateTimeOrDash(DateTime? value) =>
    value == null ? '—' : _dateTime(value);
