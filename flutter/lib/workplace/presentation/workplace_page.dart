import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';
import '../../device_control/domain/device_control_models.dart';
import '../../shared/presentation/widgets/module_widgets.dart';
import '../application/workplace_controller.dart';
import '../domain/workplace_models.dart';

class WorkplacePage extends StatefulWidget {
  const WorkplacePage({
    super.key,
    required this.controller,
    required this.devices,
    required this.canCreateMultipleLocations,
  });

  final WorkplaceController controller;
  final List<Device> devices;
  final bool canCreateMultipleLocations;

  @override
  State<WorkplacePage> createState() => _WorkplacePageState();
}

class _WorkplacePageState extends State<WorkplacePage> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.isLoading && widget.controller.locations.isEmpty) {
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
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.strings.text('spaces')),
            bottom: TabBar(
              tabs: [
                Tab(text: context.strings.text('sites')),
                Tab(text: context.strings.text('rooms')),
                Tab(text: context.strings.text('assignments')),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _LocationsTab(
                controller: widget.controller,
                canCreateMultiple: widget.canCreateMultipleLocations,
              ),
              _RoomsTab(controller: widget.controller),
              _AssignmentsTab(
                controller: widget.controller,
                devices: widget.devices,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationsTab extends StatelessWidget {
  const _LocationsTab({
    required this.controller,
    required this.canCreateMultiple,
  });
  final WorkplaceController controller;
  final bool canCreateMultiple;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ModuleBody(
        loading: controller.isLoading,
        failure: controller.failure,
        empty: controller.locations.isEmpty,
        onRetry: controller.load,
        emptyTitle: context.strings.text('noSites'),
        child: ResponsiveRecordList(
          children: controller.locations
              .map(
                (location) => RecordCard(
                  icon: location.type == 'HOME'
                      ? Icons.home_work_outlined
                      : Icons.location_city_outlined,
                  title: location.name,
                  subtitle: location.address,
                  trailing: StatusPill(label: location.type, positive: true),
                  details: [
                    '${controller.rooms.where((room) => room.locationId == location.id).length} ${context.strings.text('rooms').toLowerCase()}',
                  ],
                  actions: [
                    TextButton.icon(
                      onPressed: controller.isMutating
                          ? null
                          : () => _create(context, location),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(context.strings.text('edit')),
                    ),
                    TextButton.icon(
                      onPressed: controller.isMutating
                          ? null
                          : () async {
                              final confirmed = await showConfirmAction(
                                context,
                                title: context.strings.text('deleteSite'),
                                message: context.strings.text(
                                  'deleteSiteWarning',
                                ),
                                confirmLabel: context.strings.text('delete'),
                              );
                              if (confirmed && context.mounted) {
                                await runAction(
                                  context,
                                  controller.deleteLocation(location.id),
                                );
                              }
                            },
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
          heroTag: 'create-location',
          onPressed:
              controller.isMutating ||
                  (controller.locations.isNotEmpty && !canCreateMultiple)
              ? null
              : () => _create(context, null),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: Text(context.strings.text('newSite')),
        ),
      ),
    ],
  );

  Future<void> _create(
    BuildContext context,
    WorkplaceLocation? location,
  ) async {
    final name = TextEditingController(text: location?.name);
    final address = TextEditingController(text: location?.address);
    var type = location?.type ?? 'HOME';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            context.strings.text(location == null ? 'newSite' : 'editSite'),
          ),
          content: Column(
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
                controller: address,
                decoration: InputDecoration(
                  labelText: context.strings.text('address'),
                  suffixIcon: IconButton(
                    tooltip: context.strings.text('searchAddress'),
                    onPressed: controller.isSearchingAddresses
                        ? null
                        : () async {
                            await controller.searchAddresses(
                              address.text,
                              Localizations.localeOf(context).languageCode,
                            );
                            if (!context.mounted) return;
                            final selected =
                                await showModalBottomSheet<AddressSuggestion>(
                                  context: context,
                                  showDragHandle: true,
                                  builder: (context) => SafeArea(
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: controller.addressSuggestions
                                          .map(
                                            (item) => ListTile(
                                              leading: const Icon(
                                                Icons.location_on_outlined,
                                              ),
                                              title: Text(item.displayName),
                                              subtitle: Text(
                                                '${item.latitude.toStringAsFixed(5)}, ${item.longitude.toStringAsFixed(5)}',
                                              ),
                                              onTap: () =>
                                                  Navigator.pop(context, item),
                                            ),
                                          )
                                          .toList(growable: false),
                                    ),
                                  ),
                                );
                            if (selected != null) {
                              address.text = selected.displayName;
                            }
                          },
                    icon: controller.isSearchingAddresses
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(
                  labelText: context.strings.text('type'),
                ),
                items: const [
                  DropdownMenuItem(value: 'HOME', child: Text('Home')),
                  DropdownMenuItem(value: 'BUSINESS', child: Text('Business')),
                  DropdownMenuItem(value: 'BRANCH', child: Text('Branch')),
                ],
                onChanged: (value) => setState(() => type = value ?? type),
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
                name.text.trim().isNotEmpty && address.text.trim().isNotEmpty,
              ),
              child: Text(context.strings.text('save')),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      final action = location == null
          ? controller.createLocation(
              name.text.trim(),
              address.text.trim(),
              type,
            )
          : controller.updateLocation(
              location,
              name.text.trim(),
              address.text.trim(),
              type,
            );
      await runAction(context, action);
    }
    name.dispose();
    address.dispose();
  }
}

class _RoomsTab extends StatelessWidget {
  const _RoomsTab({required this.controller});
  final WorkplaceController controller;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ModuleBody(
        loading: controller.isLoading,
        failure: controller.failure,
        empty: controller.rooms.isEmpty,
        onRetry: controller.load,
        emptyTitle: context.strings.text('noRooms'),
        child: ResponsiveRecordList(
          children: controller.rooms
              .map(
                (room) => RecordCard(
                  icon: Icons.meeting_room_outlined,
                  title: room.name,
                  subtitle: controller.locationName(room.locationId),
                  details: [room.floor],
                  actions: [
                    TextButton.icon(
                      onPressed: controller.isMutating
                          ? null
                          : () => _create(context, room),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(context.strings.text('edit')),
                    ),
                    TextButton.icon(
                      onPressed: controller.isMutating
                          ? null
                          : () async {
                              final confirmed = await showConfirmAction(
                                context,
                                title: context.strings.text('deleteRoom'),
                                message: context.strings.text(
                                  'deleteRoomWarning',
                                ),
                                confirmLabel: context.strings.text('delete'),
                              );
                              if (confirmed && context.mounted) {
                                await runAction(
                                  context,
                                  controller.deleteRoom(room.id),
                                );
                              }
                            },
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
          heroTag: 'create-room',
          onPressed: controller.locations.isEmpty || controller.isMutating
              ? null
              : () => _create(context, null),
          icon: const Icon(Icons.add_home_work_outlined),
          label: Text(context.strings.text('newRoom')),
        ),
      ),
    ],
  );

  Future<void> _create(BuildContext context, WorkplaceRoom? room) async {
    final name = TextEditingController(text: room?.name);
    final floor = TextEditingController(text: room?.floor);
    var locationId = room?.locationId ?? controller.locations.first.id;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.strings.text(room == null ? 'newRoom' : 'editRoom'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: locationId,
              decoration: InputDecoration(
                labelText: context.strings.text('sites'),
              ),
              items: controller.locations
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => locationId = value ?? locationId,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: name,
              decoration: InputDecoration(
                labelText: context.strings.text('name'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: floor,
              decoration: InputDecoration(
                labelText: context.strings.text('floor'),
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
            onPressed: () =>
                Navigator.pop(context, name.text.trim().isNotEmpty),
            child: Text(context.strings.text('save')),
          ),
        ],
      ),
    );
    if (submitted == true && context.mounted) {
      final action = room == null
          ? controller.createRoom(
              locationId,
              name.text.trim(),
              floor.text.trim(),
            )
          : controller.updateRoom(
              room,
              locationId,
              name.text.trim(),
              floor.text.trim(),
            );
      await runAction(context, action);
    }
    name.dispose();
    floor.dispose();
  }
}

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({required this.controller, required this.devices});
  final WorkplaceController controller;
  final List<Device> devices;

  String _deviceName(int id) =>
      devices
          .where((item) => item.id == id)
          .map((item) => item.name)
          .firstOrNull ??
      'Device #$id';

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ModuleBody(
        loading: controller.isLoading,
        failure: controller.failure,
        empty: controller.assignments.isEmpty,
        onRetry: controller.load,
        emptyTitle: context.strings.text('noAssignments'),
        child: ResponsiveRecordList(
          children: controller.assignments
              .map(
                (assignment) => RecordCard(
                  icon: Icons.device_hub_rounded,
                  title: _deviceName(assignment.deviceId),
                  subtitle: controller.locationName(assignment.locationId),
                  details: [controller.roomName(assignment.roomId)],
                  actions: [
                    TextButton.icon(
                      onPressed: controller.isMutating
                          ? null
                          : () => _create(context, assignment),
                      icon: const Icon(Icons.drive_file_move_outline),
                      label: Text(context.strings.text('move')),
                    ),
                    TextButton.icon(
                      onPressed: controller.isMutating
                          ? null
                          : () => runAction(
                              context,
                              controller.deleteAssignment(assignment.id),
                            ),
                      icon: const Icon(Icons.link_off_rounded),
                      label: Text(context.strings.text('unassign')),
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
          heroTag: 'assign-device',
          onPressed:
              devices.isEmpty ||
                  controller.locations.isEmpty ||
                  controller.isMutating
              ? null
              : () => _create(context, null),
          icon: const Icon(Icons.add_link_rounded),
          label: Text(context.strings.text('assignDevice')),
        ),
      ),
    ],
  );

  Future<void> _create(
    BuildContext context,
    DeviceAssignment? assignment,
  ) async {
    var deviceId = assignment?.deviceId ?? devices.first.id;
    var locationId = assignment?.locationId ?? controller.locations.first.id;
    int? roomId = assignment?.roomId;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final availableRooms = controller.rooms
              .where((item) => item.locationId == locationId)
              .toList(growable: false);
          return AlertDialog(
            title: Text(
              context.strings.text(
                assignment == null ? 'assignDevice' : 'moveDevice',
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: deviceId,
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
                  onChanged: assignment == null
                      ? (value) => deviceId = value ?? deviceId
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: locationId,
                  decoration: InputDecoration(
                    labelText: context.strings.text('sites'),
                  ),
                  items: controller.locations
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() {
                    locationId = value ?? locationId;
                    roomId = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: roomId,
                  decoration: InputDecoration(
                    labelText: context.strings.text('room'),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(context.strings.text('noRoom')),
                    ),
                    ...availableRooms.map(
                      (item) => DropdownMenuItem<int?>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => roomId = value,
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
                child: Text(context.strings.text('save')),
              ),
            ],
          );
        },
      ),
    );
    if (submitted == true && context.mounted) {
      final action = assignment == null
          ? controller.assignDevice(deviceId, locationId, roomId)
          : controller.moveAssignment(assignment, locationId, roomId);
      await runAction(context, action);
    }
  }
}
