import 'package:flutter/foundation.dart';

import '../../shared/domain/app_failure.dart';
import '../domain/billing_models.dart';
import '../domain/billing_repository.dart';

final class BillingController extends ChangeNotifier {
  BillingController(this._repository);
  final BillingRepository _repository;

  List<Plan> plans = const [];
  Subscription? subscription;
  List<Payment> payments = const [];
  List<Invoice> invoices = const [];
  AppFailure? failure;
  bool isLoading = false;
  bool isMutating = false;

  Plan? get activePlan {
    final code = subscription?.active == true ? subscription?.planCode : null;
    if (code == null) return null;
    return plans.where((plan) => plan.code == code).firstOrNull;
  }

  bool canCreateDevice(int currentCount) {
    final plan = activePlan;
    if (plan == null) return false;
    return plan.maxDevices == null || currentCount < plan.maxDevices!;
  }

  bool canCreateRoutine(int currentCount) {
    final plan = activePlan;
    if (plan == null) return false;
    return plan.maxRoutines == null || currentCount < plan.maxRoutines!;
  }

  bool canCreateAlert(int currentCount) {
    final plan = activePlan;
    if (plan == null) return false;
    return plan.maxAlerts == null || currentCount < plan.maxAlerts!;
  }

  bool get canExportReports => activePlan?.reportExportEnabled ?? false;

  bool get canAccessEnergyHistory =>
      const {'PROFESSIONAL', 'ENTERPRISE'}.contains(activePlan?.code);

  bool get canUseMultipleLocations => activePlan?.code == 'ENTERPRISE';

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    failure = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        _repository.plans(),
        _repository.currentSubscription(),
        _repository.payments(),
        _repository.invoices(),
      ]);
      plans = result[0] as List<Plan>;
      subscription = result[1] as Subscription?;
      payments = result[2] as List<Payment>;
      invoices = result[3] as List<Invoice>;
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

  Future<bool> checkout(
    Plan plan,
    String holder,
    String card,
    String expiration,
    String cvv,
  ) => mutate(
    () => _repository.checkout(
      planCode: plan.code,
      holderName: holder,
      cardNumber: card,
      expirationDate: expiration,
      cvv: cvv,
    ),
  );

  Future<bool> cancel() => mutate(_repository.cancelCurrent);
}
