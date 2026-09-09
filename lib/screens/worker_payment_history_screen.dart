import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

class WorkerPaymentHistoryScreen extends StatefulWidget {
  final Worker worker;

  const WorkerPaymentHistoryScreen({super.key, required this.worker});

  @override
  State<WorkerPaymentHistoryScreen> createState() =>
      _WorkerPaymentHistoryScreenState();
}

class _WorkerPaymentHistoryScreenState
    extends State<WorkerPaymentHistoryScreen> {
  List<WagePayment> _payments = [];
  bool _loading = true;

  Worker get worker => widget.worker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final payments = await context
        .read<AppProvider>()
        .repo
        .getWagePayments(workerId: worker.id!);
    if (mounted) {
      setState(() {
        _payments = payments;
        _loading = false;
      });
    }
  }

  double get _totalPaid => _payments.fold(0, (sum, p) => sum + p.amount);

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppProvider>().settings.currency;
    final isContract = worker.wageType == WageType.contract;
    final balance = worker.contractAmount - _totalPaid;

    return Scaffold(
      appBar: AppBar(
        title: Text('${worker.name} — Payments'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Contract balance banner ───────────────────────────────
                if (isContract && !_loading)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.navySoft
                        : AppColors.sky,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contract: ${Formatters.money(worker.contractAmount, currency: currency)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                'Paid: ${Formatters.money(_totalPaid, currency: currency)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              balance < 0 ? 'Overpaid' : 'Balance',
                              style: TextStyle(
                                fontSize: 11,
                                color: balance < 0
                                    ? AppColors.danger
                                    : AppColors.success,
                              ),
                            ),
                            Text(
                              Formatters.money(balance.abs(),
                                  currency: currency),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: balance < 0
                                    ? AppColors.danger
                                    : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // ── Total paid banner (daily wage workers) ────────────────
                if (!isContract && _payments.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.navySoft
                        : AppColors.sky,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Paid',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          Formatters.money(_totalPaid, currency: currency),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                        ),
                      ],
                    ),
                  ),

                // ── List ──────────────────────────────────────────────────
                Expanded(
                  child: _payments.isEmpty
                      ? const EmptyState(
                          message: 'No payments recorded for this worker.',
                          icon: Icons.account_balance_wallet_outlined,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _payments.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final pmt = _payments[i];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.success
                                      .withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.payments_outlined,
                                    color: AppColors.success,
                                  ),
                                ),
                                title: Text(
                                  Formatters.money(pmt.amount,
                                      currency: currency),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  [
                                    Formatters.dateDisplay(pmt.date),
                                    if (pmt.projectName != null &&
                                        pmt.projectName!.isNotEmpty)
                                      pmt.projectName!,
                                    if (pmt.note.isNotEmpty) pmt.note,
                                  ].join(' · '),
                                ),
                                isThreeLine: pmt.note.isNotEmpty,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
