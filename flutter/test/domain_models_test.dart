import 'package:energycore_flutter/device_control/domain/device_control_models.dart';
import 'package:energycore_flutter/notifications/domain/notification_models.dart';
import 'package:energycore_flutter/reporting/domain/reporting_models.dart';
import 'package:energycore_flutter/iam/domain/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnergyCore domain rules', () {
    test('goal progress is normalized between zero and one', () {
      const goal = EnergyGoal(
        id: 1,
        title: 'Reduce consumption',
        targetKilowattHours: 100,
        currentKilowattHours: 125,
        deadline: null,
        status: 'ACTIVE',
        scopeName: 'All operations',
      );

      expect(goal.progress, 1);
    });

    test('device availability and power state follow backend status', () {
      const active = Device(
        id: 1,
        name: 'Lamp',
        room: 'Lab',
        type: 'LIGHT',
        powerWatts: 10,
        status: 'ON',
      );
      const maintenance = Device(
        id: 2,
        name: 'HVAC',
        room: 'Office',
        type: 'AIR_CONDITIONER',
        powerWatts: 900,
        status: 'MAINTENANCE',
      );

      expect(active.isOn, isTrue);
      expect(active.isUnavailable, isFalse);
      expect(maintenance.isUnavailable, isTrue);
    });

    test('notification preferences update without losing other values', () {
      const original = NotificationPreference(
        emailEnabled: true,
        pushEnabled: true,
        inAppEnabled: true,
        criticalOnly: false,
        quietHoursEnabled: false,
        dailySummaryEnabled: true,
        weeklySummaryEnabled: false,
        monthlyReportEnabled: true,
      );

      final updated = original.copyWith(quietHoursEnabled: true);

      expect(updated.quietHoursEnabled, isTrue);
      expect(updated.emailEnabled, isTrue);
      expect(updated.monthlyReportEnabled, isTrue);
    });

    test('access profiles expose the same permissions as the web client', () {
      const owner = AuthenticatedUser(
        id: 1,
        fullName: 'Owner',
        email: 'owner@energycore.test',
        status: 'ACTIVE',
        accessProfileName: 'OWNER',
      );
      const guest = AuthenticatedUser(
        id: 2,
        fullName: 'Guest',
        email: 'guest@energycore.test',
        status: 'ACTIVE',
        accessProfileName: 'GUEST',
      );

      expect(owner.hasPermission('MANAGE_BILLING'), isTrue);
      expect(guest.hasPermission('CONTROL_DEVICES'), isTrue);
      expect(guest.hasPermission('VIEW_ENERGY'), isFalse);
    });

    test('routine input preserves advanced scheduling choices', () {
      final startsOn = DateTime(2026, 9, 4);
      final input = CreateRoutineInput(
        name: 'Office weekdays',
        targetType: 'ROOM',
        targetId: 8,
        action: 'TURN_OFF',
        time: '19:30',
        repeatType: 'WEEKLY',
        daysOfWeek: const ['MON', 'TUE', 'WED', 'THU', 'FRI'],
        intervalDays: null,
        startsOn: startsOn,
      );

      expect(input.targetType, 'ROOM');
      expect(input.daysOfWeek, hasLength(5));
      expect(input.startsOn, startsOn);
    });

    test('operation mode input keeps integrated automation policies', () {
      const input = CreateOperationModeInput(
        locationId: 3,
        name: 'Night savings',
        description: 'Reduces non-critical consumption.',
        roomIds: [7],
        groupIds: [],
        deviceIds: [10, 11],
        turnOnDeviceIds: [],
        turnOffDeviceIds: [],
        keepOnDeviceIds: [],
        routineIds: [],
        routinesToEnableIds: [],
        routinesToDisableIds: [],
        goalIds: [5],
        internalRoutines: [
          OperationModeRoutineInput(
            name: 'Power down lab',
            targetType: 'GROUP',
            targetId: 4,
            action: 'TURN_OFF',
            triggerTime: '22:00',
          ),
        ],
        allDay: false,
        startsAt: '20:00',
        endsAt: '06:00',
        ruleProfileId: 2,
        preferenceId: 9,
        applyRuleProfile: true,
        applyNotificationPreference: true,
        applyRoutines: true,
        preserveCriticalSound: true,
      );

      expect(input.internalRoutines.single.targetType, 'GROUP');
      expect(input.goalIds, [5]);
      expect(input.applyNotificationPreference, isTrue);
    });
  });
}
