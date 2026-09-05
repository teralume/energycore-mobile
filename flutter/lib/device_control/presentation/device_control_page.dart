import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';
import '../../notifications/domain/notification_models.dart';
import '../../reporting/domain/reporting_models.dart';
import '../../shared/presentation/widgets/module_widgets.dart';
import '../../workplace/domain/workplace_models.dart';
import '../application/device_control_controller.dart';
import '../domain/device_control_models.dart';
import 'device_control_editors.dart';

class DeviceControlPage extends StatefulWidget {
  const DeviceControlPage({
    super.key,
    required this.controller,
    required this.locations,
    required this.rooms,
    required this.assignments,
    required this.goals,
    required this.ruleProfiles,
    required this.notificationPreferenceId,
    required this.canCreateDevice,
    required this.canCreateRoutine,
  });

  final DeviceControlController controller;
  final List<WorkplaceLocation> locations;
  final List<WorkplaceRoom> rooms;
  final List<DeviceAssignment> assignments;
  final List<EnergyGoal> goals;
  final List<AlertRuleProfile> ruleProfiles;
  final int? notificationPreferenceId;
  final bool canCreateDevice;
  final bool canCreateRoutine;

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.devices.isEmpty && !widget.controller.isLoading) {
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
        length: 4,
        child: SafeArea(
          child: Column(
            children: [
              ModuleHeader(
                eyebrow: context.strings.text('operations'),
                title: context.strings.text('deviceControlTitle'),
                description: context.strings.text('deviceControlDescription'),
                action: IconButton.filledTonal(
                  tooltip: context.strings.text('refresh'),
                  onPressed: widget.controller.isLoading
                      ? null
                      : widget.controller.load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: context.strings.text('devices')),
                  Tab(text: context.strings.text('groups')),
                  Tab(text: context.strings.text('routines')),
                  Tab(text: context.strings.text('modes')),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _DevicesTab(
                      controller: widget.controller,
                      canCreate: widget.canCreateDevice,
                    ),
                    _GroupsTab(controller: widget.controller),
                    _RoutinesTab(
                      controller: widget.controller,
                      locations: widget.locations,
                      rooms: widget.rooms,
                      canCreate: widget.canCreateRoutine,
                    ),
                    _ModesTab(
                      controller: widget.controller,
                      locations: widget.locations,
                      rooms: widget.rooms,
                      assignments: widget.assignments,
                      goals: widget.goals,
                      ruleProfiles: widget.ruleProfiles,
                      notificationPreferenceId: widget.notificationPreferenceId,
                    ),
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

class _DevicesTab extends StatelessWidget {
  const _DevicesTab({required this.controller, required this.canCreate});
  final DeviceControlController controller;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModuleBody(
          loading: controller.isLoading,
          failure: controller.failure,
          empty: controller.devices.isEmpty,
          onRetry: controller.load,
          emptyTitle: context.strings.text('noDevices'),
          child: RefreshIndicator(
            onRefresh: controller.load,
            child: ResponsiveRecordList(
              children: controller.devices
                  .map(
                    (device) => RecordCard(
                      icon: _deviceIcon(device.type),
                      title: device.name,
                      subtitle: device.room,
                      trailing: StatusPill(
                        label: device.status,
                        positive: device.isOn,
                      ),
                      details: [
                        device.type,
                        '${device.powerWatts.toStringAsFixed(0)} W',
                      ],
                      actions: [
                        FilledButton.tonalIcon(
                          onPressed:
                              device.isUnavailable || controller.isMutating
                              ? null
                              : () => runAction(
                                  context,
                                  controller.toggleDevice(device),
                                ),
                          icon: Icon(
                            device.isOn
                                ? Icons.power_settings_new_rounded
                                : Icons.power_rounded,
                          ),
                          label: Text(
                            context.strings.text(
                              device.isOn ? 'turnOff' : 'turnOn',
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: controller.isMutating
                              ? null
                              : () => _editDevice(context, device),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(context.strings.text('edit')),
                        ),
                        TextButton.icon(
                          onPressed: controller.isMutating
                              ? null
                              : () => _deleteDevice(context, device),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(context.strings.text('delete')),
                        ),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            heroTag: 'pair-device',
            onPressed: controller.isMutating || !canCreate
                ? null
                : () => _chooseDeviceAction(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(context.strings.text('addDevice')),
          ),
        ),
      ],
    );
  }

  Future<void> _chooseDeviceAction(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline_rounded),
              title: Text(context.strings.text('createDevice')),
              onTap: () => Navigator.pop(context, 'create'),
            ),
            ListTile(
              leading: const Icon(Icons.add_link_rounded),
              title: Text(context.strings.text('pairDevice')),
              onTap: () => Navigator.pop(context, 'pair'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'create':
        await _editDevice(context, null);
      case 'pair':
        await _pairDevice(context);
    }
  }

  Future<void> _editDevice(BuildContext context, Device? device) async {
    final name = TextEditingController(text: device?.name);
    final room = TextEditingController(text: device?.room);
    final watts = TextEditingController(
      text: device == null ? '' : device.powerWatts.toStringAsFixed(0),
    );
    var type = device?.type ?? 'PLUG';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            context.strings.text(
              device == null ? 'createDevice' : 'editDevice',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: context.strings.text('deviceName'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: room,
                  decoration: InputDecoration(
                    labelText: context.strings.text('room'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: InputDecoration(
                    labelText: context.strings.text('type'),
                  ),
                  items: const ['PLUG', 'LIGHT', 'SWITCH', 'SENSOR', 'OTHER']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => type = value ?? type),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: watts,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.strings.text('powerWatts'),
                    suffixText: 'W',
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
                name.text.trim().length >= 3 &&
                    (double.tryParse(watts.text.replaceAll(',', '.')) ?? 0) > 0,
              ),
              child: Text(context.strings.text('save')),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      final power = double.parse(watts.text.replaceAll(',', '.'));
      final action = device == null
          ? controller.createDevice(
              name.text.trim(),
              room.text.trim(),
              type,
              power,
            )
          : controller.updateDevice(
              device,
              name.text.trim(),
              room.text.trim(),
              type,
              power,
            );
      await runAction(context, action);
    }
    name.dispose();
    room.dispose();
    watts.dispose();
  }

  Future<void> _deleteDevice(BuildContext context, Device device) async {
    final confirmed = await showConfirmAction(
      context,
      title: context.strings.text('deleteDevice'),
      message: context.strings.text('deleteDeviceWarning'),
      confirmLabel: context.strings.text('delete'),
    );
    if (!context.mounted || !confirmed) return;
    await runAction(context, controller.deleteDevice(device));
  }

  Future<void> _pairDevice(BuildContext context) async {
    final code = TextEditingController();
    final alias = TextEditingController();
    final room = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.strings.text('pairDevice')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: code,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.strings.text('pairingCode'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alias,
                decoration: InputDecoration(
                  labelText: context.strings.text('deviceName'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: room,
                decoration: InputDecoration(
                  labelText: context.strings.text('room'),
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
            onPressed: () =>
                Navigator.pop(context, code.text.trim().isNotEmpty),
            child: Text(context.strings.text('connect')),
          ),
        ],
      ),
    );
    if (submitted == true && context.mounted) {
      final success = await controller.pairDevice(
        code.text.trim(),
        alias.text.trim(),
        room.text.trim(),
      );
      if (context.mounted) showActionResult(context, success);
    }
    code.dispose();
    alias.dispose();
    room.dispose();
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab({required this.controller});
  final DeviceControlController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModuleBody(
          loading: controller.isLoading,
          failure: controller.failure,
          empty: controller.groups.isEmpty,
          onRetry: controller.load,
          emptyTitle: context.strings.text('noGroups'),
          child: ResponsiveRecordList(
            children: controller.groups
                .map(
                  (group) => RecordCard(
                    icon: Icons.hub_outlined,
                    title: group.name,
                    subtitle: group.description,
                    details: [
                      '${group.deviceIds.length} ${context.strings.text('devices').toLowerCase()}',
                    ],
                    actions: [
                      FilledButton.tonalIcon(
                        onPressed: controller.isMutating
                            ? null
                            : () => runAction(
                                context,
                                controller.executeGroup(group, 'ON'),
                              ),
                        icon: const Icon(Icons.power_rounded),
                        label: Text(context.strings.text('turnOn')),
                      ),
                      TextButton.icon(
                        onPressed: controller.isMutating
                            ? null
                            : () => runAction(
                                context,
                                controller.executeGroup(group, 'OFF'),
                              ),
                        icon: const Icon(Icons.power_settings_new_rounded),
                        label: Text(context.strings.text('turnOff')),
                      ),
                      TextButton.icon(
                        onPressed: controller.isMutating
                            ? null
                            : () => _createGroup(context, group),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(context.strings.text('edit')),
                      ),
                      TextButton.icon(
                        onPressed: controller.isMutating
                            ? null
                            : () => _deleteGroup(context, group),
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
            heroTag: 'create-group',
            onPressed: controller.devices.isEmpty || controller.isMutating
                ? null
                : () => _createGroup(context, null),
            icon: const Icon(Icons.add_rounded),
            label: Text(context.strings.text('newGroup')),
          ),
        ),
      ],
    );
  }

  Future<void> _createGroup(BuildContext context, DeviceGroup? group) async {
    final name = TextEditingController(text: group?.name);
    final description = TextEditingController(text: group?.description);
    final selected = <int>{...?group?.deviceIds};
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            context.strings.text(group == null ? 'newGroup' : 'editGroup'),
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
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
                  const SizedBox(height: 10),
                  ...controller.devices.map(
                    (device) => CheckboxListTile(
                      value: selected.contains(device.id),
                      title: Text(device.name),
                      subtitle: Text(device.room),
                      onChanged: (value) => setState(() {
                        value == true
                            ? selected.add(device.id)
                            : selected.remove(device.id);
                      }),
                    ),
                  ),
                ],
              ),
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
                name.text.trim().isNotEmpty && selected.isNotEmpty,
              ),
              child: Text(context.strings.text('save')),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      final action = group == null
          ? controller.createGroup(
              name.text.trim(),
              description.text.trim(),
              selected.toList(growable: false),
            )
          : controller.updateGroup(
              group,
              name.text.trim(),
              description.text.trim(),
              selected.toList(growable: false),
            );
      await runAction(context, action);
    }
    name.dispose();
    description.dispose();
  }

  Future<void> _deleteGroup(BuildContext context, DeviceGroup group) async {
    final confirmed = await showConfirmAction(
      context,
      title: context.strings.text('deleteGroup'),
      message: context.strings.text('deleteGroupWarning'),
      confirmLabel: context.strings.text('delete'),
    );
    if (!context.mounted || !confirmed) return;
    await runAction(context, controller.deleteGroup(group));
  }
}

class _RoutinesTab extends StatelessWidget {
  const _RoutinesTab({
    required this.controller,
    required this.locations,
    required this.rooms,
    required this.canCreate,
  });
  final DeviceControlController controller;
  final List<WorkplaceLocation> locations;
  final List<WorkplaceRoom> rooms;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModuleBody(
          loading: controller.isLoading,
          failure: controller.failure,
          empty: controller.routines.isEmpty,
          onRetry: controller.load,
          emptyTitle: context.strings.text('noRoutines'),
          child: ResponsiveRecordList(
            children: controller.routines
                .map(
                  (routine) => RecordCard(
                    icon: Icons.schedule_rounded,
                    title: routine.name,
                    subtitle: '${routine.targetName} · ${routine.time}',
                    trailing: Switch(
                      value: routine.enabled,
                      onChanged: controller.isMutating
                          ? null
                          : (_) => runAction(
                              context,
                              controller.toggleRoutine(routine),
                            ),
                    ),
                    details: [
                      routine.action,
                      '${routine.applicableDeviceCount} devices',
                    ],
                    actions: [
                      FilledButton.tonalIcon(
                        onPressed: controller.isMutating
                            ? null
                            : () => runAction(
                                context,
                                controller.executeRoutine(routine),
                              ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(context.strings.text('runNow')),
                      ),
                      TextButton.icon(
                        onPressed: controller.isMutating
                            ? null
                            : () => _deleteRoutine(context, routine),
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
            heroTag: 'create-routine',
            onPressed:
                controller.devices.isEmpty ||
                    controller.isMutating ||
                    !canCreate
                ? null
                : () => _createRoutine(context),
            icon: const Icon(Icons.add_alarm_rounded),
            label: Text(context.strings.text('newRoutine')),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteRoutine(BuildContext context, Routine routine) async {
    final confirmed = await showConfirmAction(
      context,
      title: context.strings.text('deleteRoutine'),
      message: context.strings.text('deleteRoutineWarning'),
      confirmLabel: context.strings.text('delete'),
    );
    if (!context.mounted || !confirmed) return;
    await runAction(context, controller.deleteRoutine(routine));
  }

  Future<void> _createRoutine(BuildContext context) async {
    final input = await showCreateRoutineDialog(
      context,
      devices: controller.devices,
      groups: controller.groups,
      locations: locations,
      rooms: rooms,
    );
    if (input != null && context.mounted) {
      final success = await controller.createRoutine(input);
      if (context.mounted) showActionResult(context, success);
    }
  }
}

class _ModesTab extends StatelessWidget {
  const _ModesTab({
    required this.controller,
    required this.locations,
    required this.rooms,
    required this.assignments,
    required this.goals,
    required this.ruleProfiles,
    required this.notificationPreferenceId,
  });
  final DeviceControlController controller;
  final List<WorkplaceLocation> locations;
  final List<WorkplaceRoom> rooms;
  final List<DeviceAssignment> assignments;
  final List<EnergyGoal> goals;
  final List<AlertRuleProfile> ruleProfiles;
  final int? notificationPreferenceId;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModuleBody(
          loading: controller.isLoading,
          failure: controller.failure,
          empty: controller.modes.isEmpty,
          onRetry: controller.load,
          emptyTitle: context.strings.text('noModes'),
          child: ResponsiveRecordList(
            children: controller.modes
                .map(
                  (mode) => RecordCard(
                    icon: Icons.tune_rounded,
                    title: mode.name,
                    subtitle: mode.description,
                    trailing: StatusPill(
                      label: mode.status,
                      positive: mode.isActive,
                    ),
                    details: [
                      '${mode.deviceIds.length} devices',
                      mode.allDay
                          ? context.strings.text('allDay')
                          : '${mode.startsAt}–${mode.endsAt}',
                    ],
                    actions: [
                      FilledButton.tonalIcon(
                        onPressed: mode.isActive || controller.isMutating
                            ? null
                            : () => runAction(
                                context,
                                controller.activateMode(mode),
                              ),
                        icon: const Icon(Icons.bolt_rounded),
                        label: Text(context.strings.text('activate')),
                      ),
                      TextButton.icon(
                        onPressed: controller.isMutating
                            ? null
                            : () => _previewMode(context, mode),
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(context.strings.text('preview')),
                      ),
                      TextButton.icon(
                        onPressed: controller.isMutating
                            ? null
                            : () => _archiveMode(context, mode),
                        icon: const Icon(Icons.archive_outlined),
                        label: Text(context.strings.text('archive')),
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
            heroTag: 'create-mode',
            onPressed:
                locations.isEmpty ||
                    controller.devices.isEmpty ||
                    controller.isMutating
                ? null
                : () => _createMode(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(context.strings.text('newMode')),
          ),
        ),
      ],
    );
  }

  Future<void> _previewMode(BuildContext context, OperationMode mode) async {
    final preview = await controller.previewMode(mode);
    if (!context.mounted || preview == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${context.strings.text('preview')}: ${mode.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(preview.locationName),
              const SizedBox(height: 12),
              _previewLine(
                context,
                Icons.devices_other_rounded,
                '${preview.affectedDeviceIds.length} ${context.strings.text('affectedDevices')}',
              ),
              _previewLine(
                context,
                Icons.block_rounded,
                '${preview.ignoredDeviceIds.length} ${context.strings.text('ignoredDevices')}',
              ),
              const SizedBox(height: 14),
              Text(preview.evidence),
              const SizedBox(height: 8),
              Text(preview.explanation),
              if (preview.recommendedAction.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  preview.recommendedAction,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
  }

  Widget _previewLine(BuildContext context, IconData icon, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Future<void> _archiveMode(BuildContext context, OperationMode mode) async {
    final confirmed = await showConfirmAction(
      context,
      title: context.strings.text('archiveMode'),
      message: context.strings.text('archiveModeWarning'),
      confirmLabel: context.strings.text('archive'),
    );
    if (!context.mounted || !confirmed) return;
    await runAction(context, controller.archiveMode(mode));
  }

  Future<void> _createMode(BuildContext context) async {
    final input = await Navigator.of(context).push<CreateOperationModeInput>(
      MaterialPageRoute(
        builder: (_) => OperationModeEditorPage(
          devices: controller.devices,
          groups: controller.groups,
          locations: locations,
          rooms: rooms,
          assignments: assignments,
          goals: goals,
          ruleProfiles: ruleProfiles,
          notificationPreferenceId: notificationPreferenceId,
        ),
      ),
    );
    if (input != null && context.mounted) {
      final success = await controller.createMode(input);
      if (context.mounted) showActionResult(context, success);
    }
  }
}

IconData _deviceIcon(String type) => switch (type.toUpperCase()) {
  'LIGHT' => Icons.lightbulb_outline_rounded,
  'AIR_CONDITIONER' => Icons.ac_unit_rounded,
  'REFRIGERATOR' => Icons.kitchen_outlined,
  'COMPUTER' => Icons.computer_rounded,
  'TELEVISION' => Icons.tv_rounded,
  _ => Icons.electrical_services_rounded,
};
