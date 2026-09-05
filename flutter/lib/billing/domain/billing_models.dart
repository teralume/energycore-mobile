final class Plan {
  const Plan({
    required this.id,
    required this.code,
    required this.name,
    required this.monthlyPrice,
    required this.currency,
    required this.maxDevices,
    required this.maxRoutines,
    required this.maxAlerts,
    required this.reportExportEnabled,
  });

  final int id;
  final String code;
  final String name;
  final double monthlyPrice;
  final String currency;
  final int? maxDevices;
  final int? maxRoutines;
  final int? maxAlerts;
  final bool reportExportEnabled;
}

final class Subscription {
  const Subscription({
    required this.id,
    required this.planCode,
    required this.status,
    required this.active,
    required this.nextBillingDate,
  });

  final int id;
  final String planCode;
  final String status;
  final bool active;
  final DateTime? nextBillingDate;
}

final class Payment {
  const Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
  });

  final int id;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
}

final class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.total,
    required this.currency,
    required this.issuedAt,
  });

  final int id;
  final String number;
  final double total;
  final String currency;
  final DateTime? issuedAt;
}
