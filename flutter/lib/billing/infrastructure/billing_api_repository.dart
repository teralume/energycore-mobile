import '../../shared/infrastructure/network/api_client.dart';
import '../../shared/infrastructure/network/json_readers.dart';
import '../domain/billing_models.dart';
import '../domain/billing_repository.dart';

final class BillingApiRepository implements BillingRepository {
  const BillingApiRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<Plan>> plans() async => jsonList(await _api.get('/billing/plans'))
      .map(
        (json) => Plan(
          id: jsonInt(json['id']),
          code: jsonString(json['code']),
          name: jsonString(json['name']),
          monthlyPrice: jsonDouble(json['monthlyPrice']),
          currency: jsonString(json['currency'], 'PEN'),
          maxDevices: json['maxDevices'] is num
              ? jsonInt(json['maxDevices'])
              : null,
          maxRoutines: json['maxRoutines'] is num
              ? jsonInt(json['maxRoutines'])
              : null,
          maxAlerts: json['maxAlerts'] is num
              ? jsonInt(json['maxAlerts'])
              : null,
          reportExportEnabled: jsonBool(json['reportExportEnabled']),
        ),
      )
      .toList(growable: false);

  @override
  Future<Subscription?> currentSubscription() async {
    final response = await _api.get('/billing/subscriptions/current');
    if (response == null) return null;
    final json = jsonObject(response);
    return Subscription(
      id: jsonInt(json['id']),
      planCode: jsonString(json['planCode']),
      status: jsonString(json['status'], 'INACTIVE'),
      active: jsonBool(json['active']),
      nextBillingDate: DateTime.tryParse(jsonString(json['nextBillingDate'])),
    );
  }

  @override
  Future<List<Payment>> payments() async =>
      jsonList(await _api.get('/billing/payments'))
          .map(
            (json) => Payment(
              id: jsonInt(json['id']),
              amount: jsonDouble(json['amount']),
              currency: jsonString(json['currency'], 'PEN'),
              status: jsonString(json['status']),
              paymentMethod: jsonString(json['paymentMethod']),
            ),
          )
          .toList(growable: false);

  @override
  Future<List<Invoice>> invoices() async =>
      jsonList(await _api.get('/billing/invoices'))
          .map(
            (json) => Invoice(
              id: jsonInt(json['id']),
              number: jsonString(json['invoiceNumber']),
              total: jsonDouble(json['totalAmount']),
              currency: jsonString(json['currency'], 'PEN'),
              issuedAt: DateTime.tryParse(jsonString(json['issuedAt'])),
            ),
          )
          .toList(growable: false);

  @override
  Future<void> checkout({
    required String planCode,
    required String holderName,
    required String cardNumber,
    required String expirationDate,
    required String cvv,
  }) => _api.postVoid(
    '/billing/subscriptions/checkout',
    body: {
      'planCode': planCode,
      'holderName': holderName,
      'cardNumber': cardNumber,
      'expirationDate': expirationDate,
      'cvv': cvv,
    },
  );

  @override
  Future<void> cancelCurrent() =>
      _api.deleteVoid('/billing/subscriptions/current');
}
