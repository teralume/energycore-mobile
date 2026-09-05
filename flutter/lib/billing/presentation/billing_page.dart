import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization/app_strings.dart';
import '../../shared/presentation/widgets/module_widgets.dart';
import '../application/billing_controller.dart';
import '../domain/billing_models.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({
    super.key,
    required this.controller,
    this.subscriptionRequired = false,
    this.onSignOut,
  });
  final BillingController controller;
  final bool subscriptionRequired;
  final VoidCallback? onSignOut;

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.isLoading && widget.controller.plans.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.controller.load(),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.strings.text(
              widget.subscriptionRequired ? 'chooseAPlan' : 'billing',
            ),
          ),
          automaticallyImplyLeading: !widget.subscriptionRequired,
          actions: [
            if (widget.onSignOut case final onSignOut?)
              IconButton(
                tooltip: context.strings.text('signOut'),
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded),
              ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: context.strings.text('plans')),
              Tab(text: context.strings.text('payments')),
              Tab(text: context.strings.text('invoices')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PlansTab(controller: widget.controller),
            _PaymentsTab(controller: widget.controller),
            _InvoicesTab(controller: widget.controller),
          ],
        ),
      ),
    ),
  );
}

class _PlansTab extends StatelessWidget {
  const _PlansTab({required this.controller});
  final BillingController controller;

  @override
  Widget build(BuildContext context) => ModuleBody(
    loading: controller.isLoading,
    failure: controller.failure,
    empty: controller.plans.isEmpty,
    onRetry: controller.load,
    emptyTitle: context.strings.text('noPlans'),
    child: Column(
      children: [
        if (controller.subscription case final subscription?)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(
                  '${context.strings.text('currentPlan')}: ${subscription.planCode}',
                ),
                subtitle: Text(subscription.status),
                trailing: subscription.active
                    ? TextButton(
                        onPressed: controller.isMutating
                            ? null
                            : () async {
                                final confirmed = await showConfirmAction(
                                  context,
                                  title: context.strings.text(
                                    'cancelSubscription',
                                  ),
                                  message: context.strings.text(
                                    'cancelSubscriptionWarning',
                                  ),
                                  confirmLabel: context.strings.text('confirm'),
                                );
                                if (confirmed && context.mounted) {
                                  await runAction(context, controller.cancel());
                                }
                              },
                        child: Text(context.strings.text('cancelPlan')),
                      )
                    : null,
              ),
            ),
          ),
        Expanded(
          child: ResponsiveRecordList(
            children: controller.plans
                .map(
                  (plan) => _PlanCard(
                    plan: plan,
                    current:
                        controller.subscription?.planCode == plan.code &&
                        controller.subscription?.active == true,
                    onSelect: () => _checkout(context, plan),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    ),
  );

  Future<void> _checkout(BuildContext context, Plan plan) async {
    final holder = TextEditingController();
    final card = TextEditingController();
    final expiration = TextEditingController();
    final cvv = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${context.strings.text('choosePlan')} ${plan.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: holder,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: context.strings.text('cardHolder'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: card,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.creditCardNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                ],
                decoration: InputDecoration(
                  labelText: context.strings.text('cardNumber'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiration,
                      autofillHints: const [
                        AutofillHints.creditCardExpirationDate,
                      ],
                      decoration: const InputDecoration(labelText: 'MM/YY'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: cvv,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      autofillHints: const [
                        AutofillHints.creditCardSecurityCode,
                      ],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(labelText: 'CVV'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              holder.text.trim().isNotEmpty &&
                  card.text.length >= 13 &&
                  expiration.text.trim().isNotEmpty &&
                  cvv.text.length >= 3,
            ),
            child: Text(context.strings.text('subscribe')),
          ),
        ],
      ),
    );
    if (submitted == true && context.mounted) {
      final success = await controller.checkout(
        plan,
        holder.text.trim(),
        card.text,
        expiration.text.trim(),
        cvv.text,
      );
      if (context.mounted) showActionResult(context, success);
    }
    holder.dispose();
    card.dispose();
    expiration.dispose();
    cvv.dispose();
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.current,
    required this.onSelect,
  });
  final Plan plan;
  final bool current;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (current)
                StatusPill(
                  label: context.strings.text('active'),
                  positive: true,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${plan.currency} ${plan.monthlyPrice.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 15),
          _feature(
            Icons.devices_outlined,
            '${_limit(plan.maxDevices)} devices',
          ),
          _feature(
            Icons.schedule_outlined,
            '${_limit(plan.maxRoutines)} routines',
          ),
          _feature(
            Icons.notifications_outlined,
            '${_limit(plan.maxAlerts)} alerts',
          ),
          _feature(
            Icons.file_download_outlined,
            plan.reportExportEnabled ? 'Report export' : 'Online reports',
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: current ? null : onSelect,
            child: Text(
              context.strings.text(current ? 'currentPlan' : 'choosePlan'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _feature(IconData icon, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [Icon(icon, size: 19), const SizedBox(width: 9), Text(label)],
    ),
  );

  String _limit(int? value) => value == null ? 'Unlimited' : '$value';
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({required this.controller});
  final BillingController controller;

  @override
  Widget build(BuildContext context) => ModuleBody(
    loading: controller.isLoading,
    failure: controller.failure,
    empty: controller.payments.isEmpty,
    onRetry: controller.load,
    emptyTitle: context.strings.text('noPayments'),
    child: ResponsiveRecordList(
      children: controller.payments
          .map(
            (payment) => RecordCard(
              icon: Icons.credit_card_rounded,
              title: '${payment.currency} ${payment.amount.toStringAsFixed(2)}',
              subtitle: payment.paymentMethod,
              trailing: StatusPill(
                label: payment.status,
                positive: payment.status == 'COMPLETED',
              ),
            ),
          )
          .toList(growable: false),
    ),
  );
}

class _InvoicesTab extends StatelessWidget {
  const _InvoicesTab({required this.controller});
  final BillingController controller;

  @override
  Widget build(BuildContext context) => ModuleBody(
    loading: controller.isLoading,
    failure: controller.failure,
    empty: controller.invoices.isEmpty,
    onRetry: controller.load,
    emptyTitle: context.strings.text('noInvoices'),
    child: ResponsiveRecordList(
      children: controller.invoices
          .map(
            (invoice) => RecordCard(
              icon: Icons.receipt_long_outlined,
              title: invoice.number,
              subtitle: _date(invoice.issuedAt),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    tooltip: context.strings.text('exportInvoice'),
                    onPressed: () => _copyInvoice(context, invoice),
                    icon: const Icon(Icons.download_outlined),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    ),
  );

  Future<void> _copyInvoice(BuildContext context, Invoice invoice) async {
    final contents = [
      'EnergyCore',
      'Invoice ID: ${invoice.id}',
      'Invoice Number: ${invoice.number}',
      'Amount: ${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
      'Issued At: ${invoice.issuedAt?.toIso8601String() ?? '-'}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: contents));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.strings.text('invoiceCopied'))),
    );
  }
}

String _date(DateTime? value) => value == null
    ? '—'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
