import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';
import '../../notifications/domain/notification_models.dart';
import '../../reporting/domain/reporting_models.dart';
import '../../workplace/domain/workplace_models.dart';
import '../domain/device_control_models.dart';

Future<CreateRoutineInput?> showCreateRoutineDialog(
  BuildContext context, {
  required List<Device> devices,
  required List<DeviceGroup> groups,
  required List<WorkplaceLocation> locations,
  required List<WorkplaceRoom> rooms,
}) {
  return showDialog<CreateRoutineInput>(
    context: context,
    builder: (context) => _CreateRoutineDialog(
      devices: devices,
      groups: groups,
      locations: locations,
      rooms: rooms,
    ),
  );
}

class _CreateRoutineDialog extends StatefulWidget {
  const _CreateRoutineDialog({
    required this.devices,
    required this.groups,
    required this.locations,
    required this.rooms,
  });

  final List<Device> devices;
  final List<DeviceGroup> groups;
  final List<WorkplaceLocation> locations;
  final List<WorkplaceRoom> rooms;

  @override
  State<_CreateRoutineDialog> createState() => _CreateRoutineDialogState();
}

class _CreateRoutineDialogState extends State<_CreateRoutineDialog> {
  final name = TextEditingController();
  final interval = TextEditingController(text: '2');
  String targetType = 'DEVICE';
  int? targetId;
  String action = 'TURN_ON';
  String repeatType = 'DAILY';
  final selectedDays = <String>{};
  TimeOfDay time = const TimeOfDay(hour: 8, minute: 0);
  DateTime startsOn = DateTime.now();

  @override
  void initState() {
    super.initState();
    targetId = _targets('DEVICE').firstOrNull?.$1;
  }

  @override
  void dispose() {
    name.dispose();
    interval.dispose();
    super.dispose();
  }

  List<(int, String)> _targets(String type) => switch (type) {
    'GROUP' => widget.groups.map((item) => (item.id, item.name)).toList(),
    'ROOM' => widget.rooms.map((item) => (item.id, item.name)).toList(),
    'WORKPLACE' =>
      widget.locations.map((item) => (item.id, item.name)).toList(),
    _ => widget.devices.map((item) => (item.id, item.name)).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final targets = _targets(targetType);
    final canSave =
        name.text.trim().isNotEmpty &&
        targetId != null &&
        (repeatType != 'WEEKLY' || selectedDays.isNotEmpty) &&
        (repeatType != 'CUSTOM_INTERVAL' ||
            (int.tryParse(interval.text) ?? 0) > 0);
    return AlertDialog(
      title: Text(context.strings.text('newRoutine')),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.strings.text('name'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: targetType,
                decoration: InputDecoration(
                  labelText: context.strings.text('targetType'),
                ),
                items: const ['DEVICE', 'GROUP', 'ROOM', 'WORKPLACE']
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_targetTypeLabel(context, type)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() {
                  targetType = value ?? targetType;
                  targetId = _targets(targetType).firstOrNull?.$1;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey(targetType),
                initialValue: targetId,
                decoration: InputDecoration(
                  labelText: context.strings.text('target'),
                ),
                items: targets
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.$1,
                        child: Text(item.$2),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => targetId = value),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'TURN_ON',
                    label: Text(context.strings.text('turnOn')),
                    icon: const Icon(Icons.power_rounded),
                  ),
                  ButtonSegment(
                    value: 'TURN_OFF',
                    label: Text(context.strings.text('turnOff')),
                    icon: const Icon(Icons.power_off_rounded),
                  ),
                ],
                selected: {action},
                onSelectionChanged: (value) =>
                    setState(() => action = value.first),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: repeatType,
                decoration: InputDecoration(
                  labelText: context.strings.text('repeat'),
                ),
                items: const ['ONCE', 'DAILY', 'WEEKLY', 'CUSTOM_INTERVAL']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_repeatLabel(context, value)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) =>
                    setState(() => repeatType = value ?? repeatType),
              ),
              if (repeatType == 'WEEKLY') ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(context.strings.text('daysOfWeek')),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children:
                      const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                          .map(
                            (day) => FilterChip(
                              label: Text(_dayLabel(context, day)),
                              selected: selectedDays.contains(day),
                              onSelected: (selected) => setState(() {
                                selected
                                    ? selectedDays.add(day)
                                    : selectedDays.remove(day);
                              }),
                            ),
                          )
                          .toList(growable: false),
                ),
              ],
              if (repeatType == 'CUSTOM_INTERVAL') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: interval,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: context.strings.text('intervalDays'),
                  ),
                ),
              ],
              if (repeatType == 'ONCE' || repeatType == 'CUSTOM_INTERVAL') ...[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(context.strings.text('startsOn')),
                  trailing: Text(_date(startsOn)),
                  onTap: _pickDate,
                ),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: Text(context.strings.text('schedule')),
                trailing: Text(time.format(context)),
                onTap: _pickTime,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.strings.text('cancel')),
        ),
        FilledButton(
          onPressed: canSave ? _submit : null,
          child: Text(context.strings.text('save')),
        ),
      ],
    );
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(context: context, initialTime: time);
    if (value != null) setState(() => time = value);
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: startsOn,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (value != null) setState(() => startsOn = value);
  }

  void _submit() {
    Navigator.pop(
      context,
      CreateRoutineInput(
        name: name.text.trim(),
        targetType: targetType,
        targetId: targetId!,
        action: action,
        time: _time(time),
        repeatType: repeatType,
        daysOfWeek: selectedDays.toList(growable: false),
        intervalDays: repeatType == 'CUSTOM_INTERVAL'
            ? int.tryParse(interval.text)
            : null,
        startsOn: repeatType == 'ONCE' || repeatType == 'CUSTOM_INTERVAL'
            ? startsOn
            : null,
      ),
    );
  }
}

class OperationModeEditorPage extends StatefulWidget {
  const OperationModeEditorPage({
    super.key,
    required this.devices,
    required this.groups,
    required this.locations,
    required this.rooms,
    required this.assignments,
    required this.goals,
    required this.ruleProfiles,
    required this.notificationPreferenceId,
  });

  final List<Device> devices;
  final List<DeviceGroup> groups;
  final List<WorkplaceLocation> locations;
  final List<WorkplaceRoom> rooms;
  final List<DeviceAssignment> assignments;
  final List<EnergyGoal> goals;
  final List<AlertRuleProfile> ruleProfiles;
  final int? notificationPreferenceId;

  @override
  State<OperationModeEditorPage> createState() =>
      _OperationModeEditorPageState();
}

class _OperationModeEditorPageState extends State<OperationModeEditorPage> {
  final name = TextEditingController();
  final description = TextEditingController();
  final routineName = TextEditingController();
  int? locationId;
  String scope = 'WORKPLACE';
  int? roomId;
  bool allDay = true;
  TimeOfDay startsAt = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endsAt = const TimeOfDay(hour: 18, minute: 0);
  final goalIds = <int>{};
  int? ruleProfileId;
  bool applyRuleProfile = false;
  bool applyNotificationPreference = false;
  bool preserveCriticalSound = true;
  String routineTargetType = 'DEVICE';
  int? routineTargetId;
  String routineAction = 'TURN_ON';
  TimeOfDay routineTime = const TimeOfDay(hour: 8, minute: 0);
  final internalRoutines = <OperationModeRoutineInput>[];

  @override
  void initState() {
    super.initState();
    locationId = widget.locations.firstOrNull?.id;
    routineTargetId = _routineTargets('DEVICE').firstOrNull?.$1;
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    routineName.dispose();
    super.dispose();
  }

  List<WorkplaceRoom> get scopedRooms => widget.rooms
      .where((item) => item.locationId == locationId)
      .toList(growable: false);

  Set<int> get scopedDeviceIds {
    if (locationId == null || (scope == 'ROOM' && roomId == null)) {
      return const <int>{};
    }
    return widget.assignments
        .where(
          (item) =>
              item.locationId == locationId &&
              (scope != 'ROOM' || item.roomId == roomId),
        )
        .map((item) => item.deviceId)
        .toSet();
  }

  List<(int, String)> _routineTargets(String type) {
    if (type == 'GROUP') {
      return widget.groups
          .where((group) => group.deviceIds.any(scopedDeviceIds.contains))
          .map((group) => (group.id, group.name))
          .toList(growable: false);
    }
    return widget.devices
        .where((device) => scopedDeviceIds.contains(device.id))
        .map((device) => (device.id, device.name))
        .toList(growable: false);
  }

  List<EnergyGoal> get scopedGoals => widget.goals
      .where((goal) {
        if (goal.scopeType == 'GENERAL') return true;
        if (goal.scopeType == 'WORKPLACE') return goal.scopeId == locationId;
        if (goal.scopeType == 'ROOM') {
          return scopedRooms.any(
            (room) =>
                room.id == goal.scopeId &&
                (scope != 'ROOM' || room.id == roomId),
          );
        }
        if (goal.scopeType == 'DEVICE') {
          return scopedDeviceIds.contains(goal.scopeId);
        }
        if (goal.scopeType == 'GROUP') {
          return widget.groups.any(
            (group) =>
                group.id == goal.scopeId &&
                group.deviceIds.any(scopedDeviceIds.contains),
          );
        }
        return false;
      })
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final targets = _routineTargets(routineTargetType);
    return Scaffold(
      appBar: AppBar(title: Text(context.strings.text('newMode'))),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            _section(context, context.strings.text('modeDetails'), [
              TextField(
                controller: name,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.strings.text('name'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.strings.text('description'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: locationId,
                decoration: InputDecoration(
                  labelText: context.strings.text('sites'),
                ),
                items: widget.locations
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() {
                  locationId = value;
                  roomId = null;
                  internalRoutines.clear();
                  routineTargetId = _routineTargets('DEVICE').firstOrNull?.$1;
                }),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'WORKPLACE',
                    label: Text(context.strings.text('entireSite')),
                  ),
                  ButtonSegment(
                    value: 'ROOM',
                    label: Text(context.strings.text('room')),
                  ),
                ],
                selected: {scope},
                onSelectionChanged: (value) => setState(() {
                  scope = value.first;
                  roomId = null;
                  internalRoutines.clear();
                  routineTargetId = _routineTargets('DEVICE').firstOrNull?.$1;
                }),
              ),
              if (scope == 'ROOM') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: roomId,
                  decoration: InputDecoration(
                    labelText: context.strings.text('room'),
                  ),
                  items: scopedRooms
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() {
                    roomId = value;
                    internalRoutines.clear();
                    routineTargetId = _routineTargets('DEVICE').firstOrNull?.$1;
                  }),
                ),
              ],
            ]),
            _section(context, context.strings.text('schedule'), [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.strings.text('allDay')),
                value: allDay,
                onChanged: (value) => setState(() => allDay = value),
              ),
              if (!allDay)
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.strings.text('startTime')),
                        trailing: Text(startsAt.format(context)),
                        onTap: () => _pickModeTime(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.strings.text('endTime')),
                        trailing: Text(endsAt.format(context)),
                        onTap: () => _pickModeTime(false),
                      ),
                    ),
                  ],
                ),
            ]),
            _section(context, context.strings.text('internalRoutines'), [
              TextField(
                controller: routineName,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.strings.text('routineName'),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'DEVICE',
                    label: Text(context.strings.text('devices')),
                  ),
                  ButtonSegment(
                    value: 'GROUP',
                    label: Text(context.strings.text('groups')),
                  ),
                ],
                selected: {routineTargetType},
                onSelectionChanged: (value) => setState(() {
                  routineTargetType = value.first;
                  routineTargetId = _routineTargets(
                    routineTargetType,
                  ).firstOrNull?.$1;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey('$routineTargetType-$locationId-$roomId'),
                initialValue: routineTargetId,
                decoration: InputDecoration(
                  labelText: context.strings.text('target'),
                ),
                items: targets
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.$1,
                        child: Text(item.$2),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => routineTargetId = value),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'TURN_ON',
                    label: Text(context.strings.text('turnOn')),
                  ),
                  ButtonSegment(
                    value: 'TURN_OFF',
                    label: Text(context.strings.text('turnOff')),
                  ),
                ],
                selected: {routineAction},
                onSelectionChanged: (value) =>
                    setState(() => routineAction = value.first),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.strings.text('triggerTime')),
                trailing: Text(routineTime.format(context)),
                onTap: _pickRoutineTime,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed:
                      routineName.text.trim().isNotEmpty &&
                          routineTargetId != null
                      ? _addRoutine
                      : null,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(context.strings.text('addRoutine')),
                ),
              ),
              ...internalRoutines.asMap().entries.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(entry.value.name),
                  subtitle: Text(
                    '${_targetName(entry.value)} · ${entry.value.triggerTime}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () =>
                        setState(() => internalRoutines.removeAt(entry.key)),
                  ),
                ),
              ),
            ]),
            if (scopedGoals.isNotEmpty)
              _section(
                context,
                context.strings.text('goals'),
                scopedGoals
                    .map(
                      (goal) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: goalIds.contains(goal.id),
                        title: Text(goal.title),
                        subtitle: Text(goal.scopeName),
                        onChanged: (selected) => setState(() {
                          selected == true
                              ? goalIds.add(goal.id)
                              : goalIds.remove(goal.id);
                        }),
                      ),
                    )
                    .toList(growable: false),
              ),
            _section(context, context.strings.text('automationPolicies'), [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.strings.text('applyRuleProfile')),
                value: applyRuleProfile,
                onChanged: widget.ruleProfiles.isEmpty
                    ? null
                    : (value) => setState(() {
                        applyRuleProfile = value;
                        if (value && ruleProfileId == null) {
                          ruleProfileId = widget.ruleProfiles.first.id;
                        }
                      }),
              ),
              if (applyRuleProfile)
                DropdownButtonFormField<int>(
                  initialValue: ruleProfileId,
                  decoration: InputDecoration(
                    labelText: context.strings.text('ruleProfile'),
                  ),
                  items: widget.ruleProfiles
                      .map(
                        (profile) => DropdownMenuItem(
                          value: profile.id,
                          child: Text(profile.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => ruleProfileId = value),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  context.strings.text('applyNotificationPreference'),
                ),
                value: applyNotificationPreference,
                onChanged: widget.notificationPreferenceId == null
                    ? null
                    : (value) =>
                          setState(() => applyNotificationPreference = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.strings.text('preserveCriticalSound')),
                value: preserveCriticalSound,
                onChanged: (value) =>
                    setState(() => preserveCriticalSound = value),
              ),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _canSave ? _submit : null,
          icon: const Icon(Icons.check_rounded),
          label: Text(context.strings.text('createMode')),
        ),
      ),
    );
  }

  bool get _canSave =>
      locationId != null &&
      name.text.trim().isNotEmpty &&
      internalRoutines.isNotEmpty &&
      (scope != 'ROOM' || roomId != null) &&
      (!applyRuleProfile || ruleProfileId != null);

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _pickModeTime(bool start) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? startsAt : endsAt,
    );
    if (value == null) return;
    setState(() => start ? startsAt = value : endsAt = value);
  }

  Future<void> _pickRoutineTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: routineTime,
    );
    if (value != null) setState(() => routineTime = value);
  }

  void _addRoutine() {
    setState(() {
      internalRoutines.add(
        OperationModeRoutineInput(
          name: routineName.text.trim(),
          targetType: routineTargetType,
          targetId: routineTargetId!,
          action: routineAction,
          triggerTime: _time(routineTime),
        ),
      );
      routineName.clear();
    });
  }

  String _targetName(OperationModeRoutineInput routine) {
    final targets = _routineTargets(routine.targetType);
    return targets
            .where((target) => target.$1 == routine.targetId)
            .firstOrNull
            ?.$2 ??
        '#${routine.targetId}';
  }

  void _submit() {
    final selectedDeviceIds = scopedDeviceIds.toList(growable: false);
    Navigator.pop(
      context,
      CreateOperationModeInput(
        locationId: locationId!,
        name: name.text.trim(),
        description: description.text.trim(),
        roomIds: scope == 'ROOM' ? [roomId!] : const [],
        groupIds: const [],
        deviceIds: selectedDeviceIds,
        turnOnDeviceIds: const [],
        turnOffDeviceIds: const [],
        keepOnDeviceIds: const [],
        routineIds: const [],
        routinesToEnableIds: const [],
        routinesToDisableIds: const [],
        goalIds: goalIds.toList(growable: false),
        internalRoutines: List.unmodifiable(internalRoutines),
        allDay: allDay,
        startsAt: allDay ? '00:00' : _time(startsAt),
        endsAt: allDay ? '23:59' : _time(endsAt),
        ruleProfileId: applyRuleProfile ? ruleProfileId : null,
        preferenceId: applyNotificationPreference
            ? widget.notificationPreferenceId
            : null,
        applyRuleProfile: applyRuleProfile,
        applyNotificationPreference: applyNotificationPreference,
        applyRoutines: internalRoutines.isNotEmpty,
        preserveCriticalSound: preserveCriticalSound,
      ),
    );
  }
}

String _targetTypeLabel(BuildContext context, String value) => switch (value) {
  'GROUP' => context.strings.text('groups'),
  'ROOM' => context.strings.text('rooms'),
  'WORKPLACE' => context.strings.text('sites'),
  _ => context.strings.text('devices'),
};

String _repeatLabel(BuildContext context, String value) => switch (value) {
  'ONCE' => context.strings.text('once'),
  'WEEKLY' => context.strings.text('weekly'),
  'CUSTOM_INTERVAL' => context.strings.text('customInterval'),
  _ => context.strings.text('daily'),
};

String _dayLabel(BuildContext context, String value) =>
    context.strings.text(switch (value) {
      'MON' => 'mondayShort',
      'TUE' => 'tuesdayShort',
      'WED' => 'wednesdayShort',
      'THU' => 'thursdayShort',
      'FRI' => 'fridayShort',
      'SAT' => 'saturdayShort',
      _ => 'sundayShort',
    });

String _time(TimeOfDay value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
