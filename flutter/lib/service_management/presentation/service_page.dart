import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';
import '../../device_control/domain/device_control_models.dart';
import '../../shared/presentation/widgets/module_widgets.dart';
import '../application/service_controller.dart';
import '../domain/service_models.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({
    super.key,
    required this.controller,
    required this.devices,
  });

  final ServiceController controller;
  final List<Device> devices;

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.isLoading &&
        widget.controller.supportTickets.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.controller.load(),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.strings.text('service')),
          bottom: TabBar(
            tabs: [
              Tab(text: context.strings.text('support')),
              Tab(text: context.strings.text('maintenance')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SupportTab(controller: widget.controller),
            _MaintenanceTab(
              controller: widget.controller,
              devices: widget.devices,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SupportTab extends StatelessWidget {
  const _SupportTab({required this.controller});
  final ServiceController controller;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ModuleBody(
        loading: controller.isLoading,
        failure: controller.failure,
        empty: controller.supportTickets.isEmpty,
        onRetry: controller.load,
        emptyTitle: context.strings.text('noSupportTickets'),
        child: ResponsiveRecordList(
          children: controller.supportTickets
              .map(
                (ticket) => RecordCard(
                  icon: Icons.support_agent_rounded,
                  title: ticket.subject,
                  subtitle: ticket.description,
                  trailing: StatusPill(
                    label: ticket.status,
                    positive:
                        ticket.status == 'RESOLVED' ||
                        ticket.status == 'CLOSED',
                  ),
                  details: [
                    ticket.priority,
                    if (ticket.createdAt != null) _date(ticket.createdAt!),
                  ],
                  actions: [
                    if (ticket.status == 'OPEN')
                      FilledButton.tonalIcon(
                        onPressed: controller.isMutating
                            ? null
                            : () => runAction(
                                context,
                                controller.updateSupportStatus(
                                  ticket,
                                  'RESOLVED',
                                ),
                              ),
                        icon: const Icon(Icons.task_alt_rounded),
                        label: Text(context.strings.text('resolve')),
                      ),
                    TextButton.icon(
                      onPressed: controller.isMutating
                          ? null
                          : () => _deleteSupport(context, ticket),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(context.strings.text('delete')),
                    ),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ),
      Positioned(
        right: 20,
        bottom: 20,
        child: FloatingActionButton.extended(
          heroTag: 'create-support',
          onPressed: controller.isMutating ? null : () => _create(context),
          icon: const Icon(Icons.add_comment_outlined),
          label: Text(context.strings.text('newTicket')),
        ),
      ),
    ],
  );

  Future<void> _deleteSupport(
    BuildContext context,
    SupportTicket ticket,
  ) async {
    final confirmed = await showConfirmAction(
      context,
      title: context.strings.text('deleteTicket'),
      message: context.strings.text('deleteTicketWarning'),
      confirmLabel: context.strings.text('delete'),
    );
    if (!context.mounted || !confirmed) return;
    await runAction(context, controller.deleteSupport(ticket));
  }

  Future<void> _create(BuildContext context) async {
    final subject = TextEditingController();
    final description = TextEditingController();
    var priority = 'MEDIUM';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.strings.text('newTicket')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subject,
                  decoration: InputDecoration(
                    labelText: context.strings.text('subject'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: context.strings.text('description'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: InputDecoration(
                    labelText: context.strings.text('priority'),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'LOW', child: Text('Low')),
                    DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                    DropdownMenuItem(value: 'HIGH', child: Text('High')),
                    DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                  ],
                  onChanged: (value) =>
                      setState(() => priority = value ?? priority),
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
                subject.text.trim().isNotEmpty &&
                    description.text.trim().isNotEmpty,
              ),
              child: Text(context.strings.text('send')),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      final success = await controller.createSupport(
        subject.text.trim(),
        description.text.trim(),
        priority,
      );
      if (context.mounted) showActionResult(context, success);
    }
    subject.dispose();
    description.dispose();
  }
}

class _MaintenanceTab extends StatelessWidget {
  const _MaintenanceTab({required this.controller, required this.devices});
  final ServiceController controller;
  final List<Device> devices;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ModuleBody(
        loading: controller.isLoading,
        failure: controller.failure,
        empty: controller.maintenanceTickets.isEmpty,
        onRetry: controller.load,
        emptyTitle: context.strings.text('noMaintenanceTickets'),
        child: ResponsiveRecordList(
          children: controller.maintenanceTickets
              .map(
                (ticket) => RecordCard(
                  icon: Icons.build_outlined,
                  title: ticket.deviceName,
                  subtitle: ticket.description,
                  trailing: StatusPill(
                    label: ticket.status,
                    positive: ticket.status == 'COMPLETED',
                  ),
                  details: [ticket.type, _date(ticket.scheduledDate)],
                  actions: [
                    if (ticket.status != 'COMPLETED')
                      FilledButton.tonalIcon(
                        onPressed: controller.isMutating
                            ? null
                            : () => runAction(
                                context,
                                controller.updateMaintenanceStatus(
                                  ticket,
                                  'COMPLETED',
                                ),
                              ),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(context.strings.text('complete')),
                      ),
                    TextButton.icon(
                      onPressed: controller.isMutating
                          ? null
                          : () => _deleteMaintenance(context, ticket),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(context.strings.text('delete')),
                    ),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ),
      Positioned(
        right: 20,
        bottom: 20,
        child: FloatingActionButton.extended(
          heroTag: 'create-maintenance',
          onPressed: devices.isEmpty || controller.isMutating
              ? null
              : () => _create(context),
          icon: const Icon(Icons.home_repair_service_outlined),
          label: Text(context.strings.text('scheduleMaintenance')),
        ),
      ),
    ],
  );

  Future<void> _deleteMaintenance(
    BuildContext context,
    MaintenanceTicket ticket,
  ) async {
    final confirmed = await showConfirmAction(
      context,
      title: context.strings.text('deleteMaintenance'),
      message: context.strings.text('deleteTicketWarning'),
      confirmLabel: context.strings.text('delete'),
    );
    if (!context.mounted || !confirmed) return;
    await runAction(context, controller.deleteMaintenance(ticket));
  }

  Future<void> _create(BuildContext context) async {
    var device = devices.first;
    var type = 'INSPECTION';
    var date = DateTime.now().add(const Duration(days: 1));
    final description = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.strings.text('scheduleMaintenance')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: device.id,
                  decoration: InputDecoration(
                    labelText: context.strings.text('devices'),
                  ),
                  items: devices
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() {
                    device = devices.firstWhere((item) => item.id == value);
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: InputDecoration(
                    labelText: context.strings.text('type'),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'INSPECTION',
                      child: Text('Inspection'),
                    ),
                    DropdownMenuItem(value: 'REPAIR', child: Text('Repair')),
                    DropdownMenuItem(
                      value: 'REPLACEMENT',
                      child: Text('Replacement'),
                    ),
                    DropdownMenuItem(
                      value: 'INSTALLATION',
                      child: Text('Installation'),
                    ),
                  ],
                  onChanged: (value) => setState(() => type = value ?? type),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.strings.text('description'),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(context.strings.text('scheduledDate')),
                  trailing: Text(_date(date)),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: now,
                      lastDate: DateTime(now.year + 3),
                      initialDate: date,
                    );
                    if (picked != null) setState(() => date = picked);
                  },
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
                  Navigator.pop(context, description.text.trim().isNotEmpty),
              child: Text(context.strings.text('save')),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      final success = await controller.createMaintenance(
        device.id,
        device.name,
        type,
        description.text.trim(),
        date,
      );
      if (context.mounted) showActionResult(context, success);
    }
    description.dispose();
  }
}

String _date(DateTime? value) => value == null
    ? '—'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
