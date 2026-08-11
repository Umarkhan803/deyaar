import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_state.dart';

/// Daily Attendance — project dropdown, assigned workers, P/A/H + overtime (img4).
class DailyAttendanceScreen extends StatefulWidget {
  final bool embedded;
  const DailyAttendanceScreen({super.key, this.embedded = false});

  @override
  State<DailyAttendanceScreen> createState() => _DailyAttendanceScreenState();
}

class _DailyAttendanceScreenState extends State<DailyAttendanceScreen> {
  late String _date;
  int? _projectId;
  List<Worker> _workers = [];
  final Map<int, AttendanceStatus> _status = {};
  final Map<int, TextEditingController> _overtime = {};
  final Map<int, int?> _existingIds = {};
  bool _loadingWorkers = false;

  @override
  void initState() {
    super.initState();
    _date = Formatters.todayIso();
  }

  @override
  void dispose() {
    for (final c in _overtime.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadWorkersForProject(int? projectId) async {
    setState(() {
      _loadingWorkers = true;
      _projectId = projectId;
    });
    for (final c in _overtime.values) {
      c.dispose();
    }
    _overtime.clear();
    _status.clear();
    _existingIds.clear();

    if (projectId == null) {
      setState(() {
        _workers = [];
        _loadingWorkers = false;
      });
      return;
    }

    final app = context.read<AppProvider>();
    final workers = await app.repo.getWorkersForProject(projectId);
    final records = await app.repo.getAttendance(date: _date, projectId: projectId);
    for (final w in workers) {
      final existing = records.where((a) => a.workerId == w.id).toList();
      final rec = existing.isEmpty ? null : existing.first;
      _status[w.id!] = rec?.status ?? AttendanceStatus.present;
      _overtime[w.id!] = TextEditingController(
        text: (rec?.overtimeHours ?? 0).toStringAsFixed(0),
      );
      _existingIds[w.id!] = rec?.id;
    }
    if (!mounted) return;
    setState(() {
      _workers = workers;
      _loadingWorkers = false;
    });
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _date = DateFormat('yyyy-MM-dd').format(picked));
    await _loadWorkersForProject(_projectId);
  }

  Future<void> _saveAll() async {
    if (_projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a project first')),
      );
      return;
    }
    final app = context.read<AppProvider>();
    for (final w in _workers) {
      final status = _status[w.id!] ?? AttendanceStatus.present;
      final ot = double.tryParse(_overtime[w.id!]?.text ?? '0') ?? 0;
      final wage = status == AttendanceStatus.absent
          ? 0.0
          : status == AttendanceStatus.half
              ? w.dailyWageDefault / 2
              : w.dailyWageDefault;
      await app.saveAttendance(
        Attendance(
          id: _existingIds[w.id!],
          workerId: w.id!,
          projectId: _projectId,
          date: _date,
          status: status,
          wage: wage,
          overtimeHours: ot,
        ),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance saved')),
    );
    await _loadWorkersForProject(_projectId);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final presentCount = _status.values
        .where(
          (s) =>
              s == AttendanceStatus.present || s == AttendanceStatus.half,
        )
        .length;
    final absentCount =
        _status.values.where((s) => s == AttendanceStatus.absent).length;
    final halfCount =
        _status.values.where((s) => s == AttendanceStatus.half).length;
    final unmarked = _workers.length - _status.length;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                if (!widget.embedded) ...[
                  AppHeader(
                    onBack: () => Navigator.pop(context),
                    trailing: IconButton(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Daily Attendance',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$presentCount present · ${_workers.length} workers',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(
                        DateFormat('MMM dd, yyyy')
                            .format(DateTime.tryParse(_date) ?? DateTime.now())
                            .toUpperCase(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  // ignore: deprecated_member_use
                  value: _projectId,
                  decoration: const InputDecoration(
                    labelText: 'Project',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Select a project'),
                    ),
                    ...app.projects.map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ),
                  ],
                  onChanged: _loadWorkersForProject,
                ),
                const SizedBox(height: 14),
                if (_projectId != null)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.warning.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.groups_outlined),
                              SizedBox(width: 8),
                              Text(
                                "Today's Shift",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$presentCount / ${_workers.length}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Text('Workers Present'),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _workers.isEmpty
                                  ? 0
                                  : presentCount / _workers.length,
                              minHeight: 10,
                              color: AppColors.primaryBlue,
                              backgroundColor:
                                  AppColors.danger.withValues(alpha: 0.25),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _Legend(
                                color: AppColors.primaryBlue,
                                label: 'Present (P)',
                                count: presentCount,
                              ),
                              _Legend(
                                color: AppColors.danger,
                                label: 'Absent (A)',
                                count: absentCount,
                              ),
                              _Legend(
                                color: AppColors.warning,
                                label: 'Half Day (H)',
                                count: halfCount,
                              ),
                              _Legend(
                                color: AppColors.muted,
                                label: '—',
                                count: unmarked < 0 ? 0 : unmarked,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (_projectId == null)
                  const EmptyState(
                    message: 'Select a project to list assigned workers.',
                    icon: Icons.engineering_outlined,
                  )
                else if (_loadingWorkers)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ))
                else if (_workers.isEmpty)
                  const EmptyState(
                    message:
                        'No workers assigned to this project. Assign projects when adding/editing a worker.',
                    icon: Icons.person_off_outlined,
                  )
                else ...[
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Worker Details',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        'Attendance Status',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._workers.map((w) {
                    final status =
                        _status[w.id!] ?? AttendanceStatus.present;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primaryBlue,
                                  child: Text(
                                    w.name.isNotEmpty
                                        ? w.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        w.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        w.displayId,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                _StatusBtn(
                                  label: 'P',
                                  selected: status == AttendanceStatus.present,
                                  color: AppColors.primaryBlue,
                                  onTap: () => setState(
                                    () => _status[w.id!] =
                                        AttendanceStatus.present,
                                  ),
                                ),
                                _StatusBtn(
                                  label: 'A',
                                  selected: status == AttendanceStatus.absent,
                                  color: AppColors.danger,
                                  onTap: () => setState(
                                    () => _status[w.id!] =
                                        AttendanceStatus.absent,
                                  ),
                                ),
                                _StatusBtn(
                                  label: 'H',
                                  selected: status == AttendanceStatus.half,
                                  color: AppColors.warning,
                                  onTap: () => setState(
                                    () =>
                                        _status[w.id!] = AttendanceStatus.half,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text('Overtime'),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 64,
                                  child: TextField(
                                    controller: _overtime[w.id!],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('hrs'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ElevatedButton.icon(
                onPressed: _saveAll,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Attendance'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _Legend({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _StatusBtn({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
