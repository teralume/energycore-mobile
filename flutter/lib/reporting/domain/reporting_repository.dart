import 'reporting_models.dart';

abstract interface class ReportingRepository {
  Future<List<EnergyReading>> readings();
  Future<List<EnergyReading>> readingsByDate(DateTime start, DateTime end);
  Future<int> samplingSeconds();
  Future<void> updateSamplingSeconds(int seconds);
  Future<List<ConsumptionReport>> reports();
  Future<List<EnergyGoal>> goals();
  Future<List<ReportingEvent>> events();
  Future<void> generateReport(DateTime start, DateTime end);
  Future<void> deleteReport(int id);
  Future<void> createGoal({
    required String title,
    required double targetKilowattHours,
    required DateTime deadline,
    String scopeType,
    int? scopeId,
    String? scopeName,
  });
  Future<void> updateGoal({
    required int id,
    required String title,
    required double targetKilowattHours,
    required double currentKilowattHours,
    required DateTime deadline,
    required String status,
    required String scopeType,
    int? scopeId,
    String? scopeName,
  });
  Future<void> deleteGoal(int id);
}
