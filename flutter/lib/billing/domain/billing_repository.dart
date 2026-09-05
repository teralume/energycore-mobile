import 'billing_models.dart';

abstract interface class BillingRepository {
  Future<List<Plan>> plans();
  Future<Subscription?> currentSubscription();
  Future<List<Payment>> payments();
  Future<List<Invoice>> invoices();
  Future<void> checkout({
    required String planCode,
    required String holderName,
    required String cardNumber,
    required String expirationDate,
    required String cvv,
  });
  Future<void> cancelCurrent();
}
