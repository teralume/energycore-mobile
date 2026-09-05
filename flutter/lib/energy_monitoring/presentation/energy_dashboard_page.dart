import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization/app_strings.dart';
import '../application/energy_dashboard_controller.dart';
import '../domain/energy_dashboard_summary.dart';

class EnergyDashboardPage extends StatelessWidget {
  const EnergyDashboardPage({
    super.key,
    required this.controller,
    required this.userName,
    this.detailsOnly = false,
    this.canExport = false,
  });

  final EnergyDashboardController controller;
  final String userName;
  final bool detailsOnly;
  final bool canExport;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.summary == null && controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.summary == null) {
          return _LoadFailure(controller: controller);
        }

        final summary = controller.summary!;
        return RefreshIndicator(
          onRefresh: controller.load,
          child: LayoutBuilder(
            builder: (context, constraints) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth >= 900 ? 36 : 20,
                24,
                constraints.maxWidth >= 900 ? 36 : 20,
                36,
              ),
              children: [
                if (!detailsOnly) ...[
                  _DashboardHeader(userName: userName),
                  const SizedBox(height: 22),
                  _LiveEnergyCard(summary: summary),
                  const SizedBox(height: 18),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.strings.text('energy'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      if (canExport)
                        IconButton.filledTonal(
                          tooltip: context.strings.text('export'),
                          onPressed: () => _copyDashboard(context, summary),
                          icon: const Icon(Icons.download_rounded),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.strings.text('overview'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                _MetricsGrid(summary: summary),
                const SizedBox(height: 18),
                _ResponsiveContent(summary: summary, detailsOnly: detailsOnly),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyDashboard(
    BuildContext context,
    EnergyDashboardSummary summary,
  ) async {
    final rows = <String>[
      'metric,value',
      'currentWatts,${summary.currentWatts}',
      'todayKilowattHours,${summary.todayKilowattHours}',
      'todayEstimatedCost,${summary.todayEstimatedCost}',
      'projectedMonthlyCost,${summary.projectedMonthlyCost}',
      'peakWatts,${summary.peakWatts}',
      'averageWatts,${summary.averageWatts}',
      'activeDevices,${summary.activeDevices}',
      'monitoredDevices,${summary.monitoredDevices}',
      'efficiencyScore,${summary.efficiencyScore}',
      '',
      'deviceId,deviceName,room,type,watts,kilowattHours',
      ...summary.topDevices.map(
        (device) => [
          device.id,
          _csv(device.name),
          _csv(device.room),
          device.type,
          device.watts,
          device.kilowattHours,
        ].join(','),
      ),
      '',
      'room,watts,kilowattHours,activeDevices',
      ...summary.rooms.map(
        (room) => [
          _csv(room.room),
          room.watts,
          room.kilowattHours,
          room.activeDevices,
        ].join(','),
      ),
    ];
    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.strings.text('copiedToClipboard'))),
    );
  }
}

String _csv(String value) => '"${value.replaceAll('"', '""')}"';

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final nameParts = userName.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isEmpty ? userName : nameParts.first;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.strings.text('greeting')}, $firstName',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                context.strings.text('overview'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            firstName.isEmpty ? 'E' : firstName.characters.first.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveEnergyCard extends StatelessWidget {
  const _LiveEnergyCard({required this.summary});

  final EnergyDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2515), Color(0xFF123A20), Color(0xFF242509)],
        ),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.48),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final value = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.strings.text('live'),
                    style: const TextStyle(
                      color: Color(0xFF86EFAC),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _number(summary.currentWatts, decimals: 0),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontSize: compact ? 44 : 58,
                ),
              ),
              Text(
                'W · ${context.strings.text('currentPower')}',
                style: const TextStyle(color: Color(0xFFC6D0C9), fontSize: 15),
              ),
            ],
          );
          final score = Semantics(
            label:
                '${context.strings.text('efficiency')}: ${summary.efficiencyScore}%',
            child: SizedBox.square(
              dimension: compact ? 104 : 124,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.square(
                    dimension: compact ? 104 : 124,
                    child: CircularProgressIndicator(
                      value: (summary.efficiencyScore / 100).clamp(0, 1),
                      strokeWidth: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      color: scheme.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${summary.efficiencyScore}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        context.strings.text('efficiency'),
                        style: const TextStyle(
                          color: Color(0xFFB6C3B9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [value, const SizedBox(height: 22), score],
                )
              : Row(
                  children: [
                    Expanded(child: value),
                    score,
                  ],
                );
        },
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.summary});

  final EnergyDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final metrics = [
      _Metric(
        Icons.energy_savings_leaf_outlined,
        strings.text('todayEnergy'),
        '${_number(summary.todayKilowattHours)} kWh',
      ),
      _Metric(
        Icons.payments_outlined,
        strings.text('todayCost'),
        'S/ ${_number(summary.todayEstimatedCost)}',
      ),
      _Metric(
        Icons.calendar_month_outlined,
        strings.text('monthlyProjection'),
        'S/ ${_number(summary.projectedMonthlyCost)}',
      ),
      _Metric(
        Icons.power_outlined,
        strings.text('activeDevices'),
        '${summary.activeDevices}/${summary.monitoredDevices}',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: _MetricCard(metric: metric),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _Metric {
  const _Metric(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(metric.icon, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    metric.value,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveContent extends StatelessWidget {
  const _ResponsiveContent({required this.summary, required this.detailsOnly});

  final EnergyDashboardSummary summary;
  final bool detailsOnly;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final left = Column(
          children: [
            _TrendCard(points: summary.trend),
            if (detailsOnly) ...[
              const SizedBox(height: 18),
              _RoomCard(rooms: summary.rooms),
            ],
          ],
        );
        final right = Column(
          children: [
            _InsightCard(message: summary.recommendation),
            const SizedBox(height: 18),
            _DevicesCard(devices: summary.topDevices),
          ],
        );
        if (constraints.maxWidth < 760) {
          return Column(children: [left, const SizedBox(height: 18), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: left),
            const SizedBox(width: 18),
            Expanded(flex: 2, child: right),
          ],
        );
      },
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});
  final List<EnergyTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.text('trend'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 22),
            if (points.isEmpty)
              SizedBox(
                height: 190,
                child: Center(child: Text(context.strings.text('noData'))),
              )
            else
              Semantics(
                label: context.strings.text('trend'),
                child: SizedBox(
                  height: 210,
                  child: CustomPaint(
                    painter: _TrendPainter(
                      points
                          .map((point) => point.watts)
                          .toList(growable: false),
                      lineColor: scheme.primary,
                      gridColor: scheme.outline.withValues(alpha: 0.34),
                      fillColor: scheme.primary.withValues(alpha: 0.13),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(
    this.values, {
    required this.lineColor,
    required this.gridColor,
    required this.fillColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color gridColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = gridColor;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maximum = math.max(values.reduce(math.max), 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      final y = size.height - (values[i] / maximum * (size.height - 10)) - 5;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.lineColor != lineColor;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome_outlined, color: scheme.secondary),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.strings.text('recommendation'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    message.isEmpty ? context.strings.text('noData') : message,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevicesCard extends StatelessWidget {
  const _DevicesCard({required this.devices});
  final List<DeviceConsumption> devices;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.text('topDevices'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (devices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(context.strings.text('noData')),
              )
            else
              ...devices
                  .take(5)
                  .map(
                    (device) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.electrical_services_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(device.room),
                      trailing: Text('${_number(device.watts, decimals: 0)} W'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.rooms});
  final List<RoomConsumption> rooms;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.text('rooms'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (rooms.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(context.strings.text('noData')),
              )
            else
              ...rooms.map(
                (room) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.meeting_room_outlined),
                  title: Text(room.room),
                  subtitle: Text(
                    '${room.activeDevices} · ${_number(room.kilowattHours)} kWh',
                  ),
                  trailing: Text('${_number(room.watts, decimals: 0)} W'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.controller});
  final EnergyDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                controller.isOffline
                    ? Icons.wifi_off_rounded
                    : Icons.bolt_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                controller.isOffline
                    ? context.strings.text('offline')
                    : context.strings.text('loadError'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: controller.load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.strings.text('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _number(double value, {int decimals = 2}) =>
    value.toStringAsFixed(decimals);
