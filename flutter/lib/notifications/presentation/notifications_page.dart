import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';
import '../../shared/presentation/widgets/module_widgets.dart';
import '../application/notification_controller.dart';
import '../domain/notification_models.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.controller,
    required this.canCreateAlert,
  });
  final NotificationController controller;
  final bool canCreateAlert;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.isLoading && widget.controller.preferences == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.controller.load(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => DefaultTabController(
        length: 3,
        child: SafeArea(
          child: Column(
            children: [
              ModuleHeader(
                eyebrow: context.strings.text('notifications'),
                title: context.strings.text('alertsCenter'),
                description: context.strings.text('alertsDescription'),
                action: widget.controller.unreadCount == 0
                    ? null
                    : Badge.count(
                        count: widget.controller.unreadCount,
                        child: const Icon(Icons.notifications_active_outlined),
                      ),
              ),
              TabBar(
                tabs: [
                  Tab(text: context.strings.text('inbox')),
                  Tab(text: context.strings.text('rules')),
                  Tab(text: context.strings.text('preferences')),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _AlertsTab(
                      controller: widget.controller,
                      canCreate: widget.canCreateAlert,
                    ),
                    _RulesTab(controller: widget.controller),
                    _PreferencesTab(controller: widget.controller),
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

class _AlertsTab extends StatefulWidget {
  const _AlertsTab({required this.controller, required this.canCreate});
  final NotificationController controller;
  final bool canCreate;

  @override
  State<_AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<_AlertsTab> {
  String filter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final alerts = controller.alerts
        .where((alert) {
          if (filter == 'UNREAD') return !alert.read;
          if (filter == 'CRITICAL') return alert.level == 'CRITICAL';
          if (filter == 'ACTIVE') return alert.active && !alert.resolved;
          return true;
        })
        .toList(growable: false);
    return Stack(
      children: [
        ModuleBody(
          loading: controller.isLoading,
          failure: controller.failure,
          empty: controller.alerts.isEmpty,
          onRetry: controller.load,
          emptyTitle: context.strings.text('noAlerts'),
          child: RefreshIndicator(
            onRefresh: controller.load,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'ALL',
                        label: Text(context.strings.text('all')),
                      ),
                      ButtonSegment(
                        value: 'UNREAD',
                        label: Text(context.strings.text('unread')),
                      ),
                      ButtonSegment(
                        value: 'CRITICAL',
                        label: Text(context.strings.text('critical')),
                      ),
                    ],
                    selected: {filter},
                    onSelectionChanged: (value) =>
                        setState(() => filter = value.first),
                  ),
                ),
                Expanded(
                  child: ResponsiveRecordList(
                    children: alerts
                        .map(
                          (alert) => Opacity(
                            opacity: alert.read ? 0.78 : 1,
                            child: RecordCard(
                              icon: _alertIcon(alert.level),
                              title: alert.title,
                              subtitle: alert.message,
                              trailing: StatusPill(
                                label: alert.level,
                                positive: const [
                                  'STABLE',
                                  'SUCCESS',
                                ].contains(alert.level),
                              ),
                              details: [
                                alert.sourceLabel,
                                if (alert.createdAt != null)
                                  _date(alert.createdAt!),
                              ],
                              actions: [
                                FilledButton.tonalIcon(
                                  onPressed: () => _showAlert(context, alert),
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: Text(context.strings.text('details')),
                                ),
                                if (!alert.read)
                                  TextButton.icon(
                                    onPressed: controller.isMutating
                                        ? null
                                        : () => runAction(
                                            context,
                                            controller.markRead(alert),
                                          ),
                                    icon: const Icon(Icons.done_rounded),
                                    label: Text(
                                      context.strings.text('markRead'),
                                    ),
                                  ),
                                if (!alert.resolved)
                                  FilledButton.tonalIcon(
                                    onPressed: controller.isMutating
                                        ? null
                                        : () => runAction(
                                            context,
                                            controller.resolve(alert),
                                          ),
                                    icon: const Icon(Icons.task_alt_rounded),
                                    label: Text(
                                      context.strings.text('resolve'),
                                    ),
                                  ),
                                TextButton.icon(
                                  onPressed: controller.isMutating
                                      ? null
                                      : () => runAction(
                                          context,
                                          controller.dismiss(alert),
                                        ),
                                  icon: const Icon(
                                    Icons.visibility_off_outlined,
                                  ),
                                  label: Text(context.strings.text('dismiss')),
                                ),
                                TextButton.icon(
                                  onPressed: controller.isMutating
                                      ? null
                                      : () => _deleteAlert(context, alert),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                  label: Text(context.strings.text('delete')),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            heroTag: 'create-alert',
            onPressed: controller.isMutating || !widget.canCreate
                ? null
                : () => _createAlert(context),
            icon: const Icon(Icons.add_alert_outlined),
            label: Text(context.strings.text('newAlert')),
          ),
        ),
      ],
    );
  }

  Future<void> _createAlert(BuildContext context) async {
    final title = TextEditingController();
    final message = TextEditingController();
    final evidence = TextEditingController();
    final action = TextEditingController();
    var level = 'INFO';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.strings.text('newAlert')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: InputDecoration(
                    labelText: context.strings.text('title'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: message,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.strings.text('message'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: level,
                  decoration: InputDecoration(
                    labelText: context.strings.text('severity'),
                  ),
                  items: const ['INFO', 'WARNING', 'CRITICAL']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => level = value ?? level),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: evidence,
                  decoration: InputDecoration(
                    labelText: context.strings.text('evidence'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: action,
                  decoration: InputDecoration(
                    labelText: context.strings.text('recommendedAction'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.strings.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                title.text.trim().isNotEmpty && message.text.trim().isNotEmpty,
              ),
              child: Text(context.strings.text('save')),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      await runAction(
        context,
        widget.controller.createAlert(
          title.text.trim(),
          message.text.trim(),
          level,
          evidence.text.trim(),
          action.text.trim(),
        ),
      );
    }
    title.dispose();
    message.dispose();
    evidence.dispose();
    action.dispose();
  }

  Future<void> _showAlert(BuildContext context, EnergyAlert alert) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(alert.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(label: alert.level),
                const SizedBox(height: 14),
                Text(alert.message),
                if (alert.evidence.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    context.strings.text('evidence'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(alert.evidence),
                ],
                if (alert.explanation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    context.strings.text('explanation'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(alert.explanation),
                ],
                if (alert.recommendedAction.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    context.strings.text('recommendedAction'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(alert.recommendedAction),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.strings.text('close')),
            ),
          ],
        ),
      );

  Future<void> _deleteAlert(BuildContext context, EnergyAlert alert) async {
    final confirmed = await showConfirmAction(
      context,
      title: context.strings.text('deleteAlert'),
      message: context.strings.text('deleteAlertWarning'),
      confirmLabel: context.strings.text('delete'),
    );
    if (!context.mounted || !confirmed) return;
    await runAction(context, widget.controller.deleteAlert(alert));
  }
}

class _RulesTab extends StatelessWidget {
  const _RulesTab({required this.controller});
  final NotificationController controller;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ModuleBody(
        loading: controller.isLoading,
        failure: controller.failure,
        empty: controller.rules.isEmpty,
        onRetry: controller.load,
        emptyTitle: context.strings.text('noRules'),
        child: ResponsiveRecordList(
          children: controller.rules
              .map(
                (rule) => RecordCard(
                  icon: Icons.rule_rounded,
                  title: rule.name,
                  subtitle:
                      '${rule.metric} ${_conditionSymbol(rule.condition)} ${rule.threshold}',
                  trailing: Switch(
                    value: rule.enabled,
                    onChanged: controller.isMutating
                        ? null
                        : (_) =>
                              runAction(context, controller.toggleRule(rule)),
                  ),
                  details: [rule.level, rule.condition],
                  actions: [
                    TextButton.icon(
                      onPressed: controller.isMutating
                          ? null
                          : () => _deleteRule(context, rule),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(context.strings.text('delete')),
                    ),
                  ],
                ),
              )
              .followedBy(
                controller.profiles.map(
                  (profile) => RecordCard(
                    icon: Icons.policy_outlined,
                    title: profile.name,
                    subtitle: profile.description,
                    trailing: StatusPill(
                      label: profile.active
                          ? context.strings.text('active')
                          : context.strings.text('inactive'),
                      positive: profile.active,
                    ),
                    details: [
                      profile.mode,
                      profile.sensitivity,
                      profile.scopeType,
                    ],
                    actions: [
                      FilledButton.tonalIcon(
                        onPressed: profile.active || controller.isMutating
                            ? null
                            : () => runAction(
                                context,
                                controller.activateProfile(profile),
                              ),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: Text(context.strings.text('activate')),
                      ),
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
          heroTag: 'create-alert-rule',
          onPressed: controller.isMutating
              ? null
              : () => _chooseAction(context),
          icon: const Icon(Icons.add_alert_outlined),
          label: Text(context.strings.text('newRule')),
        ),
      ),
    ],
  );

  Future<void> _chooseAction(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_alert_outlined),
              title: Text(context.strings.text('newRule')),
              onTap: () => Navigator.pop(context, 'rule'),
            ),
            ListTile(
              leading: const Icon(Icons.policy_outlined),
              title: Text(context.strings.text('newProfile')),
              onTap: () => Navigator.pop(context, 'profile'),
            ),
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: Text(context.strings.text('evaluateRules')),
              onTap: () => Navigator.pop(context, 'evaluate'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'rule':
        await _createRule(context);
      case 'profile':
        await _createProfile(context);
      case 'evaluate':
        await _evaluate(context);
    }
  }

  Future<void> _deleteRule(BuildContext context, AlertRule rule) async {
    final confirmed = await showConfirmAction(
      context,
      title: context.strings.text('deleteRule'),
      message: context.strings.text('deleteRuleWarning'),
      confirmLabel: context.strings.text('delete'),
    );
    if (!context.mounted || !confirmed) return;
    await runAction(context, controller.deleteRule(rule));
  }

  Future<void> _createProfile(BuildContext context) async {
    final name = TextEditingController();
    final description = TextEditingController();
    var mode = 'BALANCED';
    var sensitivity = 'MEDIUM';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.strings.text('newProfile')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: context.strings.text('name'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  decoration: InputDecoration(
                    labelText: context.strings.text('description'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: mode,
                  decoration: InputDecoration(
                    labelText: context.strings.text('mode'),
                  ),
                  items: const ['BALANCED', 'STRICT', 'SILENT']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => mode = value ?? mode),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: sensitivity,
                  decoration: InputDecoration(
                    labelText: context.strings.text('sensitivity'),
                  ),
                  items: const ['LOW', 'MEDIUM', 'HIGH']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setState(() => sensitivity = value ?? sensitivity),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.strings.text('cancel')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, name.text.trim().isNotEmpty),
              child: Text(context.strings.text('save')),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      await runAction(
        context,
        controller.createProfile(
          name.text.trim(),
          description.text.trim(),
          mode,
          sensitivity,
        ),
      );
    }
    name.dispose();
    description.dispose();
  }

  Future<void> _evaluate(BuildContext context) async {
    final value = TextEditingController(text: '1000');
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.strings.text('evaluateRules')),
        content: TextField(
          controller: value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.strings.text('observedValue'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(value.text) != null),
            child: Text(context.strings.text('evaluate')),
          ),
        ],
      ),
    );
    if (submitted == true && context.mounted) {
      final success = await controller.evaluate(double.parse(value.text));
      if (!context.mounted) return;
      if (!success || controller.evaluation == null) {
        showActionResult(context, false);
      } else {
        final result = controller.evaluation!;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.strings.text('evaluationResult')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(label: result.level),
                const SizedBox(height: 12),
                Text(
                  '${context.strings.text('severity')}: ${result.severityScore.toStringAsFixed(1)}',
                ),
                const SizedBox(height: 10),
                Text(result.evidence),
                const SizedBox(height: 8),
                Text(result.explanation),
                const SizedBox(height: 8),
                Text(result.recommendedAction),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.strings.text('close')),
              ),
            ],
          ),
        );
        controller.clearEvaluation();
      }
    }
    value.dispose();
  }

  Future<void> _createRule(BuildContext context) async {
    final name = TextEditingController();
    final threshold = TextEditingController(text: '1000');
    var metric = 'WATTS';
    var condition = 'GREATER_THAN';
    var level = 'WARNING';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.strings.text('newRule')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: context.strings.text('name'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: metric,
                  decoration: InputDecoration(
                    labelText: context.strings.text('metric'),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'WATTS', child: Text('Watts')),
                    DropdownMenuItem(
                      value: 'KILOWATT_HOURS',
                      child: Text('kWh'),
                    ),
                    DropdownMenuItem(value: 'COST', child: Text('Cost')),
                  ],
                  onChanged: (value) =>
                      setState(() => metric = value ?? metric),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: condition,
                  decoration: InputDecoration(
                    labelText: context.strings.text('condition'),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'GREATER_THAN',
                      child: Text('Greater than'),
                    ),
                    DropdownMenuItem(
                      value: 'LESS_THAN',
                      child: Text('Less than'),
                    ),
                    DropdownMenuItem(value: 'EQUALS', child: Text('Equals')),
                  ],
                  onChanged: (value) =>
                      setState(() => condition = value ?? condition),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: threshold,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.strings.text('threshold'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: level,
                  decoration: InputDecoration(
                    labelText: context.strings.text('severity'),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'INFO', child: Text('Info')),
                    DropdownMenuItem(value: 'WARNING', child: Text('Warning')),
                    DropdownMenuItem(
                      value: 'CRITICAL',
                      child: Text('Critical'),
                    ),
                  ],
                  onChanged: (value) => setState(() => level = value ?? level),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.strings.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                name.text.trim().isNotEmpty &&
                    double.tryParse(threshold.text) != null,
              ),
              child: Text(context.strings.text('save')),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      final success = await controller.createRule(
        name.text.trim(),
        metric,
        condition,
        double.parse(threshold.text),
        level,
      );
      if (context.mounted) showActionResult(context, success);
    }
    name.dispose();
    threshold.dispose();
  }
}

class _PreferencesTab extends StatefulWidget {
  const _PreferencesTab({required this.controller});
  final NotificationController controller;

  @override
  State<_PreferencesTab> createState() => _PreferencesTabState();
}

class _PreferencesTabState extends State<_PreferencesTab> {
  NotificationPreference? draft;

  @override
  Widget build(BuildContext context) {
    final value = draft ?? widget.controller.preferences;
    return ModuleBody(
      loading: widget.controller.isLoading,
      failure: widget.controller.failure,
      empty: value == null,
      onRetry: widget.controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _toggle(
                    'Email',
                    Icons.email_outlined,
                    value!.emailEnabled,
                    (next) => _update(value.copyWith(emailEnabled: next)),
                  ),
                  _toggle(
                    context.strings.text('pushNotifications'),
                    Icons.notifications_outlined,
                    value.pushEnabled,
                    (next) => _update(value.copyWith(pushEnabled: next)),
                  ),
                  _toggle(
                    context.strings.text('inApp'),
                    Icons.dashboard_outlined,
                    value.inAppEnabled,
                    (next) => _update(value.copyWith(inAppEnabled: next)),
                  ),
                  _toggle(
                    context.strings.text('toastNotifications'),
                    Icons.web_asset_outlined,
                    value.toastEnabled,
                    (next) => _update(value.copyWith(toastEnabled: next)),
                  ),
                  _toggle(
                    context.strings.text('dashboardNotifications'),
                    Icons.space_dashboard_outlined,
                    value.dashboardEnabled,
                    (next) => _update(value.copyWith(dashboardEnabled: next)),
                  ),
                  const Divider(),
                  _toggle(
                    context.strings.text('criticalOnly'),
                    Icons.priority_high_rounded,
                    value.criticalOnly,
                    (next) => _update(value.copyWith(criticalOnly: next)),
                  ),
                  _toggle(
                    context.strings.text('quietHours'),
                    Icons.bedtime_outlined,
                    value.quietHoursEnabled,
                    (next) => _update(value.copyWith(quietHoursEnabled: next)),
                  ),
                  if (value.quietHoursEnabled) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            title: Text(context.strings.text('startTime')),
                            trailing: Text(value.quietHoursStart),
                            onTap: () => _pickQuietTime(value, true),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            title: Text(context.strings.text('endTime')),
                            trailing: Text(value.quietHoursEnd),
                            onTap: () => _pickQuietTime(value, false),
                          ),
                        ),
                      ],
                    ),
                    _toggle(
                      context.strings.text('criticalBreaksQuietHours'),
                      Icons.volume_up_outlined,
                      value.criticalBreaksQuietHours,
                      (next) => _update(
                        value.copyWith(criticalBreaksQuietHours: next),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: value.minimumLevel,
                      decoration: InputDecoration(
                        labelText: context.strings.text('minimumLevel'),
                      ),
                      items: const ['INFO', 'WARNING', 'CRITICAL']
                          .map(
                            (level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (level) {
                        if (level != null) {
                          _update(value.copyWith(minimumLevel: level));
                        }
                      },
                    ),
                  ),
                  _multiChoice(
                    context,
                    context.strings.text('allowedLevels'),
                    const ['STABLE', 'INFO', 'WARNING', 'CRITICAL', 'SUCCESS'],
                    value.allowedLevels,
                    (items) => _update(value.copyWith(allowedLevels: items)),
                  ),
                  _multiChoice(
                    context,
                    context.strings.text('allowedSources'),
                    const [
                      'DEVICE',
                      'GROUP',
                      'ROOM',
                      'WORKPLACE',
                      'ROUTINE',
                      'GOAL',
                      'REPORT',
                      'RULE',
                      'MODE',
                      'SYSTEM',
                    ],
                    value.allowedSourceTypes,
                    (items) =>
                        _update(value.copyWith(allowedSourceTypes: items)),
                  ),
                  _toggle(
                    context.strings.text('groupSimilarAlerts'),
                    Icons.auto_awesome_motion_outlined,
                    value.groupSimilarAlerts,
                    (next) => _update(value.copyWith(groupSimilarAlerts: next)),
                  ),
                  _toggle(
                    context.strings.text('reminders'),
                    Icons.alarm_outlined,
                    value.remindersEnabled,
                    (next) => _update(value.copyWith(remindersEnabled: next)),
                  ),
                  _toggle(
                    context.strings.text('routineNightSilence'),
                    Icons.nights_stay_outlined,
                    value.routineNightSilence,
                    (next) =>
                        _update(value.copyWith(routineNightSilence: next)),
                  ),
                  _toggle(
                    context.strings.text('goalDeadlineAlerts'),
                    Icons.flag_outlined,
                    value.goalDeadlineAlerts,
                    (next) => _update(value.copyWith(goalDeadlineAlerts: next)),
                  ),
                  _toggle(
                    context.strings.text('maintenanceDeviceAlerts'),
                    Icons.build_outlined,
                    value.maintenanceDeviceAlerts,
                    (next) =>
                        _update(value.copyWith(maintenanceDeviceAlerts: next)),
                  ),
                  _toggle(
                    context.strings.text('systemRecommendations'),
                    Icons.tips_and_updates_outlined,
                    value.systemRecommendations,
                    (next) =>
                        _update(value.copyWith(systemRecommendations: next)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.hourglass_bottom_rounded),
                    title: Text(context.strings.text('cooldownMinutes')),
                    subtitle: Slider(
                      min: 0,
                      max: 60,
                      divisions: 12,
                      label: '${value.cooldownMinutes}',
                      value: value.cooldownMinutes.clamp(0, 60).toDouble(),
                      onChanged: (next) => _update(
                        value.copyWith(cooldownMinutes: next.round()),
                      ),
                    ),
                    trailing: Text('${value.cooldownMinutes} min'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.speed_rounded),
                    title: Text(context.strings.text('maxAlertsPerHour')),
                    subtitle: Slider(
                      min: 1,
                      max: 60,
                      divisions: 59,
                      label: '${value.maxAlertsPerHour}',
                      value: value.maxAlertsPerHour.clamp(1, 60).toDouble(),
                      onChanged: (next) => _update(
                        value.copyWith(maxAlertsPerHour: next.round()),
                      ),
                    ),
                    trailing: Text('${value.maxAlertsPerHour}'),
                  ),
                  const Divider(),
                  _toggle(
                    context.strings.text('dailySummary'),
                    Icons.today_outlined,
                    value.dailySummaryEnabled,
                    (next) =>
                        _update(value.copyWith(dailySummaryEnabled: next)),
                  ),
                  _toggle(
                    context.strings.text('weeklySummary'),
                    Icons.date_range_outlined,
                    value.weeklySummaryEnabled,
                    (next) =>
                        _update(value.copyWith(weeklySummaryEnabled: next)),
                  ),
                  _toggle(
                    context.strings.text('monthlyReport'),
                    Icons.calendar_month_outlined,
                    value.monthlyReportEnabled,
                    (next) =>
                        _update(value.copyWith(monthlyReportEnabled: next)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: value.defaultDeliveryMode,
                      decoration: InputDecoration(
                        labelText: context.strings.text('deliveryMode'),
                      ),
                      items: const ['BANNER', 'QUIET', 'INBOX_ONLY', 'MUTED']
                          .map(
                            (mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (mode) {
                        if (mode != null) {
                          _update(value.copyWith(defaultDeliveryMode: mode));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: widget.controller.isMutating
                ? null
                : () async {
                    final success = await widget.controller.savePreferences(
                      value,
                    );
                    if (!context.mounted) return;
                    showActionResult(context, success);
                    if (success) setState(() => draft = null);
                  },
            icon: const Icon(Icons.save_outlined),
            label: Text(context.strings.text('savePreferences')),
          ),
        ],
      ),
    );
  }

  Widget _toggle(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SwitchListTile(
    value: value,
    onChanged: onChanged,
    secondary: Icon(icon),
    title: Text(label),
  );

  Widget _multiChoice(
    BuildContext context,
    String title,
    List<String> options,
    List<String> selected,
    ValueChanged<List<String>> onChanged,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: options
              .map((option) {
                final active = selected.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: active,
                  onSelected: (next) {
                    if (!next && selected.length == 1) return;
                    final values = selected.toSet();
                    next ? values.add(option) : values.remove(option);
                    onChanged(values.toList(growable: false));
                  },
                );
              })
              .toList(growable: false),
        ),
      ],
    ),
  );

  Future<void> _pickQuietTime(NotificationPreference value, bool start) async {
    final source = start ? value.quietHoursStart : value.quietHoursEnd;
    final parts = source.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 22,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected == null) return;
    final formatted =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    _update(
      start
          ? value.copyWith(quietHoursStart: formatted)
          : value.copyWith(quietHoursEnd: formatted),
    );
  }

  void _update(NotificationPreference value) => setState(() => draft = value);
}

IconData _alertIcon(String level) => switch (level) {
  'CRITICAL' => Icons.error_outline_rounded,
  'WARNING' => Icons.warning_amber_rounded,
  'SUCCESS' => Icons.check_circle_outline_rounded,
  _ => Icons.info_outline_rounded,
};

String _conditionSymbol(String value) => switch (value) {
  'GREATER_THAN' => '>',
  'LESS_THAN' => '<',
  'EQUALS' => '=',
  _ => value,
};

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
