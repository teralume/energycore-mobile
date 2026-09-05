import 'package:flutter/foundation.dart';

import '../../shared/domain/app_failure.dart';
import '../domain/energy_dashboard_summary.dart';
import '../domain/energy_repository.dart';

final class EnergyDashboardController extends ChangeNotifier {
  EnergyDashboardController(this._repository);

  final EnergyRepository _repository;

  EnergyDashboardSummary? summary;
  AppFailure? failure;
  bool isLoading = false;

  bool get isOffline => failure?.isOffline ?? false;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    failure = null;
    notifyListeners();
    try {
      summary = await _repository.dashboardSummary();
    } on AppFailure catch (error) {
      failure = error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    summary = null;
    failure = null;
    isLoading = false;
    notifyListeners();
  }
}
