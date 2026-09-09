import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class WorkerAttendanceHistoryScreen extends StatefulWidget {
  final Worker worker;

  const WorkerAttendanceHistoryScreen({super.key, required this.worker});

  @override
  State<WorkerAttendanceHistoryScreen> createState() =>
      _WorkerAttendanceHistoryScreenState();
}

class _WorkerAttendanceHistoryScreenState
    extends State<WorkerAttendanceHistoryScreen> {
  List<Attendance> _records = [];
  bool _loading = true;

  Worker get worker => widget.worker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await context
        .read<AppProvider>()
        .repo
        .getAttendance(workerId: worker.id!);
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
      });
    }
  }

  // Summary counts
  int get _total => _records.length;
  int get _present =>
      _records.where((r) => r.status == AttendanceStatus.present).length;
  int get _absent =>
      _records.where((r) => r.status == AttendanceStatus.absent).length;
  int get _half =>
      _records.where((r) => r.status == AttendanceStatus.half).length;

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.danger;
      case AttendanceStatus.half:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${worker.name} — Attendance'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const EmptyState(
                  message: 'No attendance records found.',
                  icon: Icons.calendar_today_outlined,
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Summary card ──────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [AppColors.navy, AppColors.navySoft],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                color: AppColors.primaryBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Attendance Summary',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _SummaryItem(
                                  label: 'Total',
                                  value: '$_total',
                                  color: Colors.white),
                              _Divider(),
                              _SummaryItem(
                                  label: 'Present',
                                  value: '$_present',
                                  color: AppColors.success),
                              _Divider(),
                              _SummaryItem(
                                  label: 'Absent',
                                  value: '$_absent',
                                  color: AppColors.danger),
                              _Divider(),
                              _SummaryItem(
                                  label: 'Half',
                                  value: '$_half',
                                  color: AppColors.warning),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── History label ─────────────────────────────────────
                    Text(
                      'History',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),

                    // ── Records list ──────────────────────────────────────
                    ..._records.map((r) {
                      final date = DateTime.tryParse(r.date) ?? DateTime.now();
                      final dateLabel =
                          DateFormat('MMM dd, yyyy').format(date);
                      final statusColor = _statusColor(r.status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Dot indicator
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateLabel,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (r.projectName != null &&
                                      r.projectName!.isNotEmpty)
                                    Text(
                                      r.projectName!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted(context),
                                      ),
                                    ),
                                  if (r.overtimeHours > 0)
                                    Text(
                                      'OT: ${r.overtimeHours.toStringAsFixed(1)} hrs',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted(context),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                r.statusLabel.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
