import 'energy_dashboard_summary.dart';

abstract interface class EnergyRepository {
  Future<EnergyDashboardSummary> dashboardSummary();
}
