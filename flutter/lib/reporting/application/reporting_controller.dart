import 'package:flutter/foundation.dart';

import '../../shared/domain/app_failure.dart';
import '../domain/reporting_models.dart';
import '../domain/reporting_repository.dart';

final class ReportingController extends ChangeNotifier {
  ReportingController(this._repository);
  final ReportingRepository _repository;

  List<EnergyReading> readings = const [];
  List<ConsumptionReport> reports = const [];
  List<EnergyGoal> goals = const [];
  List<ReportingEvent> events = const [];
  int samplingSeconds = 30;
  AppFailure? failure;
  bool isLoading = false;
  bool isMutating = false;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    failure = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        _repository.readings(),
        _repository.reports(),
        _repository.goals(),
        _repository.events(),
      ]);
      readings = result[0] as List<EnergyReading>;
      reports = result[1] as List<ConsumptionReport>;
      goals = result[2] as List<EnergyGoal>;
      events = result[3] as List<ReportingEvent>;
      try {
        samplingSeconds = await _repository.samplingSeconds();
      } on AppFailure {
        samplingSeconds = 30;
      }
    } on AppFailure catch (error) {
      failure = error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> mutate(Future<void> Function() action) async {
    if (isMutating) return false;
    isMutating = true;
    failure = null;
    notifyListeners();
    try {
      await action();
      await load();
      return true;
    } on AppFailure catch (error) {
      failure = error;
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> generateReport(DateTime start, DateTime end) =>
      mutate(() => _repository.generateReport(start, end));
  Future<bool> deleteReport(int id) =>
      mutate(() => _repository.deleteReport(id));
  Future<bool> createGoal(String title, double target, DateTime deadline) =>
      mutate(
        () => _repository.createGoal(
          title: title,
          targetKilowattHours: target,
          deadline: deadline,
        ),
      );
  Future<bool> updateGoal(
    EnergyGoal goal,
    String title,
    double target,
    double current,
    DateTime deadline,
    String status,
  ) => mutate(
    () => _repository.updateGoal(
      id: goal.id,
      title: title,
      targetKilowattHours: target,
      currentKilowattHours: current,
      deadline: deadline,
      status: status,
      scopeType: goal.scopeType,
      scopeId: goal.scopeId,
      scopeName: goal.scopeName,
    ),
  );
  Future<bool> filterByDate(DateTime start, DateTime end) async {
    if (isLoading) return false;
    isLoading = true;
    failure = null;
    notifyListeners();
    try {
      readings = await _repository.readingsByDate(start, end);
      return true;
    } on AppFailure catch (error) {
      failure = error;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSamplingSeconds(int seconds) =>
      mutate(() => _repository.updateSamplingSeconds(seconds));
  Future<bool> deleteGoal(int id) => mutate(() => _repository.deleteGoal(id));
}
