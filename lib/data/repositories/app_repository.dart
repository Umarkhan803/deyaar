import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database.dart';
import '../models/models.dart';

class AppRepository {
  final _db = AppDatabase.instance;

  Future<AppSettings> getSettings() async {
    final db = await _db.database;
    final rows = await db.query('settings');
    final map = {for (final r in rows) r['key'] as String: r['value'] as String};
    return AppSettings(
      companyName: map['company_name'] ?? 'Deyaar Constructions',
      pinHash: map['pin_hash'],
      currency: map['currency'] ?? 'INR',
      demoSeeded: map['demo_seeded'] == '1',
      themeMode: AppThemePreference.fromString(map['theme_mode']),
      biometricEnabled: map['biometric_enabled'] == '1',
    );
  }

  Future<void> _setSetting(String key, String value) async {
    final db = await _db.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCompanyName(String name) => _setSetting('company_name', name);
  Future<void> updateCurrency(String currency) => _setSetting('currency', currency);
  Future<void> updateThemeMode(AppThemePreference mode) =>
      _setSetting('theme_mode', mode.name);
  Future<void> updateBiometricEnabled(bool enabled) =>
      _setSetting('biometric_enabled', enabled ? '1' : '0');

  String hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<void> setPin(String pin) async => _setSetting('pin_hash', hashPin(pin));

  Future<void> clearPin() async {
    final db = await _db.database;
    await db.delete('settings', where: 'key = ?', whereArgs: ['pin_hash']);
  }

  Future<bool> verifyPin(String pin) async {
    final settings = await getSettings();
    if (settings.pinHash == null || settings.pinHash!.isEmpty) return true;
    return settings.pinHash == hashPin(pin);
  }

  Future<bool> get hasPin async {
    final s = await getSettings();
    return s.pinHash != null && s.pinHash!.isNotEmpty;
  }

  Future<List<Client>> getClients() async {
    final db = await _db.database;
    final rows = await db.query('clients', orderBy: 'name COLLATE NOCASE');
    return rows.map(Client.fromMap).toList();
  }

  Future<Client?> getClient(int id) async {
    final db = await _db.database;
    final rows = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Client.fromMap(rows.first);
  }

  Future<int> upsertClient(Client client) async {
    final db = await _db.database;
    final map = client.toMap()..remove('id');
    if (client.id == null) return db.insert('clients', map);
    await db.update('clients', map, where: 'id = ?', whereArgs: [client.id]);
    return client.id!;
  }

  Future<void> deleteClient(int id) async {
    final db = await _db.database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Project>> getProjects({ProjectStatus? status}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT p.*, c.name AS client_name
      FROM projects p
      LEFT JOIN clients c ON c.id = p.client_id
      ${status != null ? "WHERE p.status = '${status.name}'" : ''}
      ORDER BY p.name COLLATE NOCASE
    ''');
    return rows.map(Project.fromMap).toList();
  }

  Future<Project?> getProject(int id) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT p.*, c.name AS client_name
      FROM projects p
      LEFT JOIN clients c ON c.id = p.client_id
      WHERE p.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    return Project.fromMap(rows.first);
  }

  Future<int> upsertProject(Project project) async {
    final db = await _db.database;
    final map = project.toMap()..remove('id');
    if (project.id == null) {
      final id = await db.insert('projects', map);
      await seedMilestonesForProject(id);
      return id;
    }
    await db.update('projects', map, where: 'id = ?', whereArgs: [project.id]);
    return project.id!;
  }

  Future<void> deleteProject(int id) async {
    final db = await _db.database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> seedMilestonesForProject(int projectId) async {
    final db = await _db.database;
    final existing = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM project_milestones WHERE project_id = ?',
          [projectId],
        )) ??
        0;
    if (existing > 0) return;
    var i = 0;
    for (final title in ProjectMilestone.defaultTitles) {
      await db.insert('project_milestones', {
        'project_id': projectId,
        'title': title,
        'done': 0,
        'sort_order': i++,
      });
    }
  }

  Future<List<ProjectMilestone>> getMilestones(int projectId) async {
    final db = await _db.database;
    await seedMilestonesForProject(projectId);
    final rows = await db.query(
      'project_milestones',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(ProjectMilestone.fromMap).toList();
  }

  Future<void> updateMilestone(ProjectMilestone m) async {
    final db = await _db.database;
    await db.update(
      'project_milestones',
      m.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [m.id],
    );
  }

  Future<List<Worker>> getWorkers() async {
    final db = await _db.database;
    final rows = await db.query('workers', orderBy: 'name COLLATE NOCASE');
    final workers = rows.map(Worker.fromMap).toList();
    for (var i = 0; i < workers.length; i++) {
      final ids = await getWorkerProjectIds(workers[i].id!);
      workers[i] = workers[i].copyWith(assignedProjectIds: ids);
    }
    return workers;
  }

  Future<Worker?> getWorker(int id) async {
    final db = await _db.database;
    final rows = await db.query('workers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final ids = await getWorkerProjectIds(id);
    return Worker.fromMap(rows.first).copyWith(assignedProjectIds: ids);
  }

  Future<List<int>> getWorkerProjectIds(int workerId) async {
    final db = await _db.database;
    final rows = await db.query(
      'worker_projects',
      columns: ['project_id'],
      where: 'worker_id = ?',
      whereArgs: [workerId],
    );
    return rows.map((r) => r['project_id'] as int).toList();
  }

  Future<void> setWorkerProjects(int workerId, List<int> projectIds) async {
    final db = await _db.database;
    await db.delete('worker_projects', where: 'worker_id = ?', whereArgs: [workerId]);
    for (final pid in projectIds.toSet()) {
      await db.insert('worker_projects', {
        'worker_id': workerId,
        'project_id': pid,
      });
    }
  }

  Future<List<Worker>> getWorkersForProject(int projectId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT w.*
      FROM workers w
      INNER JOIN worker_projects wp ON wp.worker_id = w.id
      WHERE wp.project_id = ?
      ORDER BY w.name COLLATE NOCASE
    ''', [projectId]);
    return rows.map(Worker.fromMap).toList();
  }

  Future<int> upsertWorker(Worker worker, {List<int>? projectIds}) async {
    final db = await _db.database;
    final map = worker.toMap()..remove('id');
    late final int id;
    if (worker.id == null) {
      id = await db.insert('workers', map);
    } else {
      await db.update('workers', map, where: 'id = ?', whereArgs: [worker.id]);
      id = worker.id!;
    }
    if (projectIds != null) {
      await setWorkerProjects(id, projectIds);
    }
    return id;
  }

  Future<void> deleteWorker(int id) async {
    final db = await _db.database;
    await db.delete('worker_projects', where: 'worker_id = ?', whereArgs: [id]);
    await db.delete('workers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Attendance>> getAttendance({
    String? date,
    int? projectId,
    int? workerId,
  }) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];
    if (date != null) {
      where.add('a.date = ?');
      args.add(date);
    }
    if (projectId != null) {
      where.add('a.project_id = ?');
      args.add(projectId);
    }
    if (workerId != null) {
      where.add('a.worker_id = ?');
      args.add(workerId);
    }
    final clause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery('''
      SELECT a.*, w.name AS worker_name, p.name AS project_name
      FROM attendance a
      LEFT JOIN workers w ON w.id = a.worker_id
      LEFT JOIN projects p ON p.id = a.project_id
      $clause
      ORDER BY a.date DESC, w.name COLLATE NOCASE
    ''', args);
    return rows.map(Attendance.fromMap).toList();
  }

  Future<int> upsertAttendance(Attendance item) async {
    final db = await _db.database;
    final map = item.toMap()..remove('id');
    if (item.id != null) {
      await db.update('attendance', map, where: 'id = ?', whereArgs: [item.id]);
      return item.id!;
    }
    // Match existing row for same worker + date + project
    final existing = await db.query(
      'attendance',
      where: item.projectId == null
          ? 'worker_id = ? AND date = ? AND project_id IS NULL'
          : 'worker_id = ? AND date = ? AND project_id = ?',
      whereArgs: item.projectId == null
          ? [item.workerId, item.date]
          : [item.workerId, item.date, item.projectId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update('attendance', map, where: 'id = ?', whereArgs: [id]);
      return id;
    }
    return db.insert('attendance', map);
  }

  Future<void> deleteAttendance(int id) async {
    final db = await _db.database;
    await db.delete('attendance', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> wagesBetween(String startIso, String endIso) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(wage), 0) AS total
      FROM attendance
      WHERE date >= ? AND date <= ?
        AND status IN ('present', 'half')
    ''', [startIso, endIso]);
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<WagePayment>> getWagePayments({int? workerId}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT wp.*, w.name AS worker_name, p.name AS project_name
      FROM wage_payments wp
      LEFT JOIN workers w ON w.id = wp.worker_id
      LEFT JOIN projects p ON p.id = wp.project_id
      ${workerId != null ? 'WHERE wp.worker_id = $workerId' : ''}
      ORDER BY wp.date DESC
    ''');
    return rows.map(WagePayment.fromMap).toList();
  }

  Future<double> getWorkerTotalPaid(int workerId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM wage_payments WHERE worker_id = ?',
      [workerId],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> upsertWagePayment(WagePayment item) async {
    final db = await _db.database;
    final map = item.toMap()..remove('id');
    if (item.id == null) return db.insert('wage_payments', map);
    await db.update('wage_payments', map, where: 'id = ?', whereArgs: [item.id]);
    return item.id!;
  }

  Future<void> deleteWagePayment(int id) async {
    final db = await _db.database;
    await db.delete('wage_payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Supplier>> getSuppliers() async {
    final db = await _db.database;
    final rows = await db.query('suppliers', orderBy: 'name COLLATE NOCASE');
    return rows.map(Supplier.fromMap).toList();
  }

  Future<int> upsertSupplier(Supplier s) async {
    final db = await _db.database;
    final map = s.toMap()..remove('id');
    if (s.id == null) return db.insert('suppliers', map);
    await db.update('suppliers', map, where: 'id = ?', whereArgs: [s.id]);
    return s.id!;
  }

  Future<void> deleteSupplier(int id) async {
    final db = await _db.database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MaterialItem>> getMaterials({int? projectId}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT m.*, p.name AS project_name, s.name AS supplier_name
      FROM materials m
      LEFT JOIN projects p ON p.id = m.project_id
      LEFT JOIN suppliers s ON s.id = m.supplier_id
      ${projectId != null ? 'WHERE m.project_id = $projectId' : ''}
      ORDER BY m.type COLLATE NOCASE
    ''');
    return rows.map(MaterialItem.fromMap).toList();
  }

  Future<int> upsertMaterial(MaterialItem item) async {
    final db = await _db.database;
    final map = item.toMap()..remove('id');
    if (item.id == null) return db.insert('materials', map);
    await db.update('materials', map, where: 'id = ?', whereArgs: [item.id]);
    return item.id!;
  }

  Future<void> deleteMaterial(int id) async {
    final db = await _db.database;
    await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpenses({int? projectId}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT e.*, p.name AS project_name
      FROM expenses e
      LEFT JOIN projects p ON p.id = e.project_id
      ${projectId != null ? 'WHERE e.project_id = $projectId' : ''}
      ORDER BY e.date DESC
    ''');
    return rows.map(Expense.fromMap).toList();
  }

  Future<Map<String, double>> monthlyExpensesLast6() async {
    final db = await _db.database;
    final now = DateTime.now();
    final result = <String, double>{};
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('yyyy-MM').format(d);
      result[key] = 0;
    }
    final rows = await db.rawQuery('''
      SELECT substr(date, 1, 7) AS ym, COALESCE(SUM(amount), 0) AS total
      FROM expenses
      GROUP BY ym
    ''');
    for (final r in rows) {
      final ym = r['ym'] as String?;
      if (ym != null && result.containsKey(ym)) {
        result[ym] = (r['total'] as num?)?.toDouble() ?? 0;
      }
    }
    return result;
  }

  Future<int> upsertExpense(Expense item) async {
    final db = await _db.database;
    final map = item.toMap()..remove('id');
    if (item.id == null) return db.insert('expenses', map);
    await db.update('expenses', map, where: 'id = ?', whereArgs: [item.id]);
    return item.id!;
  }

  Future<void> deleteExpense(int id) async {
    final db = await _db.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Payment>> getPayments({int? projectId}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT pay.*, p.name AS project_name
      FROM payments pay
      LEFT JOIN projects p ON p.id = pay.project_id
      ${projectId != null ? 'WHERE pay.project_id = $projectId' : ''}
      ORDER BY pay.date DESC
    ''');
    return rows.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> getPaymentReminders() async {
    final db = await _db.database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final rows = await db.rawQuery('''
      SELECT pay.*, p.name AS project_name
      FROM payments pay
      LEFT JOIN projects p ON p.id = pay.project_id
      WHERE pay.due_date IS NOT NULL AND pay.due_date != '' AND pay.due_date <= ?
      ORDER BY pay.due_date ASC
    ''', [today]);
    return rows.map(Payment.fromMap).toList();
  }

  Future<int> upsertPayment(Payment item) async {
    final db = await _db.database;
    final map = item.toMap()..remove('id');
    if (item.id == null) return db.insert('payments', map);
    await db.update('payments', map, where: 'id = ?', whereArgs: [item.id]);
    return item.id!;
  }

  Future<void> deletePayment(int id) async {
    final db = await _db.database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getReceivedForProject(int projectId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM payments WHERE project_id = ?
    ''', [projectId]);
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getPendingForProject(int projectId) async {
    final project = await getProject(projectId);
    if (project?.clientId == null) return 0;
    final client = await getClient(project!.clientId!);
    final received = await getReceivedForProject(projectId);
    return ((client?.contractValue ?? 0) - received).clamp(0, double.infinity);
  }

  Future<double> getContractValueForProject(int projectId) async {
    final project = await getProject(projectId);
    if (project?.clientId == null) return 0;
    final client = await getClient(project!.clientId!);
    return client?.contractValue ?? 0;
  }

  Future<List<SitePhoto>> getPhotos(int projectId) async {
    final db = await _db.database;
    final rows = await db.query(
      'site_photos',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'taken_at DESC',
    );
    return rows.map(SitePhoto.fromMap).toList();
  }

  Future<List<SitePhoto>> getAllPhotos() async {
    final db = await _db.database;
    final rows = await db.query('site_photos', orderBy: 'taken_at DESC');
    return rows.map(SitePhoto.fromMap).toList();
  }

  Future<Map<int, int>> getPhotoCounts() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT project_id, COUNT(*) AS cnt
      FROM site_photos
      GROUP BY project_id
    ''');
    return {
      for (final r in rows) (r['project_id'] as int): (r['cnt'] as int? ?? 0),
    };
  }

  Future<int> addPhoto(SitePhoto photo) async {
    final db = await _db.database;
    final map = photo.toMap()..remove('id');
    return db.insert('site_photos', map);
  }

  Future<void> deletePhoto(int id) async {
    final db = await _db.database;
    await db.delete('site_photos', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Quotations ----------
  Future<List<Quotation>> getQuotations() async {
    final db = await _db.database;
    final rows = await db.query('quotations', orderBy: 'created_at DESC, id DESC');
    return rows.map(Quotation.fromMap).toList();
  }

  Future<int> upsertQuotation(Quotation q) async {
    final db = await _db.database;
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    if (q.id == null) {
      return db.insert('quotations', {
        'title': q.title,
        'created_at': now,
        'updated_at': now,
      });
    }
    await db.update(
      'quotations',
      {'title': q.title, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [q.id],
    );
    return q.id!;
  }

  Future<void> deleteQuotation(int id) async {
    final db = await _db.database;
    await db.delete('quotations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Quotation>> getQuotationsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await _db.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT * FROM quotations WHERE id IN ($placeholders) ORDER BY created_at ASC, id ASC',
      ids,
    );
    return rows.map(Quotation.fromMap).toList();
  }

  Future<DashboardStats> getDashboardStats() async {
    final db = await _db.database;
    final projects = await db.rawQuery('''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN status = 'ongoing' OR status = 'planning' THEN 1 ELSE 0 END) AS ongoing,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed
      FROM projects
    ''');
    final contract = await db.rawQuery(
      'SELECT COALESCE(SUM(contract_value), 0) AS total FROM clients',
    );
    final received = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM payments',
    );
    final expenses = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses',
    );
    final wage = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM wage_payments',
    );
    final material = await db.rawQuery(
      'SELECT COALESCE(SUM(cost), 0) AS total FROM materials',
    );
    final contractTotal = (contract.first['total'] as num?)?.toDouble() ?? 0;
    final receivedTotal = (received.first['total'] as num?)?.toDouble() ?? 0;
    final expenseTotal = (expenses.first['total'] as num?)?.toDouble() ?? 0;
    final wageTotal = (wage.first['total'] as num?)?.toDouble() ?? 0;
    final materialTotal = (material.first['total'] as num?)?.toDouble() ?? 0;

    return DashboardStats(
      totalProjects: (projects.first['total'] as int?) ?? 0,
      ongoingProjects: (projects.first['ongoing'] as int?) ?? 0,
      completedProjects: (projects.first['completed'] as int?) ?? 0,
      pendingPayments: (contractTotal - receivedTotal).clamp(0, double.infinity),
      totalReceived: receivedTotal,
      totalExpenses: expenseTotal + wageTotal + materialTotal,
    );
  }

  Future<DataOverview> getDataOverview() async {
    final db = await _db.database;
    Future<int> count(String table) async =>
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table')) ?? 0;
    final payments = await count('payments');
    final expenses = await count('expenses');
    final wages = await count('wage_payments');
    return DataOverview(
      workers: await count('workers'),
      attendance: await count('attendance'),
      materials: await count('materials'),
      paymentsAndExpenses: payments + expenses + wages,
      sitePhotos: await count('site_photos'),
      suppliers: await count('suppliers'),
      projects: await count('projects'),
      clients: await count('clients'),
    );
  }

  Future<void> eraseAllData() async {
    final db = await _db.database;
    final tables = [
      'site_photos',
      'payments',
      'expenses',
      'materials',
      'wage_payments',
      'attendance',
      'project_milestones',
      'projects',
      'workers',
      'suppliers',
      'clients',
    ];
    for (final t in tables) {
      await db.delete(t);
    }
    await _setSetting('demo_seeded', '0');
  }

  Future<Map<String, double>> materialUsageReport() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT type, COALESCE(SUM(qty_used), 0) AS used
      FROM materials GROUP BY type
    ''');
    return {
      for (final r in rows) (r['type'] as String): (r['used'] as num?)?.toDouble() ?? 0
    };
  }

  Future<double> labourCostTotal() async {
    final db = await _db.database;
    final wage = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM wage_payments',
    );
    final attendance = await db.rawQuery(
      "SELECT COALESCE(SUM(wage), 0) AS total FROM attendance WHERE status IN ('present','half') OR present = 1",
    );
    final w = (wage.first['total'] as num?)?.toDouble() ?? 0;
    final a = (attendance.first['total'] as num?)?.toDouble() ?? 0;
    return w > 0 ? w : a;
  }

  Future<Map<String, double>> expensesByCategory() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT category, COALESCE(SUM(amount), 0) AS total
      FROM expenses GROUP BY category
    ''');
    return {
      for (final r in rows) (r['category'] as String): (r['total'] as num?)?.toDouble() ?? 0
    };
  }

  Future<({int clients, int workers})> importCsvRows({
    required List<List<dynamic>> rows,
    required String type,
  }) async {
    if (rows.isEmpty) return (clients: 0, workers: 0);
    final header = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    var clients = 0;
    var workers = 0;
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      String cell(String key) {
        final idx = header.indexOf(key);
        if (idx < 0 || idx >= row.length) return '';
        return row[idx].toString().trim();
      }

      if (type == 'clients' || header.contains('client_name') || header.contains('name') && header.contains('phone') && header.contains('contract_value')) {
        final name = cell('client_name').isNotEmpty ? cell('client_name') : cell('name');
        if (name.isEmpty) continue;
        await upsertClient(Client(
          name: name,
          phone: cell('phone'),
          location: cell('location'),
          contractValue: double.tryParse(cell('contract_value')) ?? 0,
          notes: cell('notes'),
        ));
        clients++;
      } else {
        final name = cell('name');
        if (name.isEmpty) continue;
        await upsertWorker(Worker(
          name: name,
          phone: cell('phone').isNotEmpty ? cell('phone') : cell('number'),
          trade: cell('trade'),
          dailyWageDefault: double.tryParse(cell('daily_wages').isNotEmpty ? cell('daily_wages') : cell('daily_wage')) ?? 0,
          experience: cell('experience'),
          address: cell('address'),
          notes: cell('notes'),
          joiningDate: cell('joining_date').isNotEmpty ? cell('joining_date') : DateFormat('yyyy-MM-dd').format(DateTime.now()),
        ));
        workers++;
      }
    }
    return (clients: clients, workers: workers);
  }

  Future<void> seedDemoIfNeeded() async {
    final settings = await getSettings();
    if (settings.demoSeeded) return;
    final db = await _db.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM clients')) ?? 0;
    if (count > 0) {
      await _setSetting('demo_seeded', '1');
      return;
    }

    final clientId = await upsertClient(const Client(
      name: 'Al Noor Developers',
      phone: '+974 5555 1234',
      location: 'Lusail, Doha',
      contractValue: 850000,
      notes: 'Villa complex Phase 1',
    ));
    final projectId = await upsertProject(Project(
      clientId: clientId,
      name: 'Lusail Villa Block A',
      location: 'Lusail, Doha',
      startDate: '2026-01-15',
      expectedEnd: '2026-09-30',
      progress: 42,
      status: ProjectStatus.ongoing,
    ));
    await upsertProject(const Project(
      name: 'Warehouse Fit-out',
      location: 'Industrial Area',
      startDate: '2025-08-01',
      expectedEnd: '2025-12-20',
      progress: 100,
      status: ProjectStatus.completed,
    ));

    final workerId = await upsertWorker(Worker(
      name: 'Ravi Kumar',
      phone: '9876543210',
      trade: 'Mason',
      dailyWageDefault: 180,
      experience: '5 years',
      joiningDate: '2026-01-01',
    ));
    await upsertWorker(Worker(
      name: 'Ahmed Hassan',
      phone: '9876501234',
      trade: 'Foreman',
      dailyWageDefault: 200,
      experience: '8 years',
      joiningDate: '2026-01-01',
    ));

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await upsertAttendance(Attendance(
      workerId: workerId,
      projectId: projectId,
      date: today,
      status: AttendanceStatus.present,
      wage: 180,
    ));
    await upsertWagePayment(WagePayment(
      workerId: workerId,
      amount: 3600,
      date: today,
      note: 'Weekly wages',
    ));

    final supplierId = await upsertSupplier(const Supplier(
      name: 'Gulf Building Supplies',
      phone: '44441234',
      notes: 'Cement & steel',
    ));

    await upsertMaterial(MaterialItem(
      projectId: projectId,
      type: StockMaterial.cement,
      name: 'OPC 53',
      qtyPurchased: 200,
      qtyUsed: 85,
      unit: 'bags',
      cost: 12000,
      openingStock: 200,
      purchasePrice: 60,
      supplierId: supplierId,
    ));
    await upsertMaterial(MaterialItem(
      projectId: projectId,
      type: StockMaterial.steel,
      name: 'TMT Bars',
      qtyPurchased: 15,
      qtyUsed: 6,
      unit: 'tons',
      cost: 45000,
      openingStock: 15,
      purchasePrice: 3000,
      supplierId: supplierId,
    ));
    await upsertMaterial(MaterialItem(
      projectId: projectId,
      type: StockMaterial.bricks,
      qtyPurchased: 10000,
      qtyUsed: 4200,
      unit: 'pcs',
      cost: 8000,
      openingStock: 10000,
      purchasePrice: 0.8,
    ));

    await upsertExpense(Expense(
      projectId: projectId,
      category: ExpenseCategory.transport,
      amount: 1500,
      date: today,
      note: 'Material delivery',
    ));
    await upsertExpense(Expense(
      projectId: projectId,
      category: ExpenseCategory.misc,
      amount: 400,
      date: today,
      note: 'Site utilities',
    ));

    await upsertPayment(Payment(
      projectId: projectId,
      type: PaymentType.advance,
      amount: 200000,
      date: '2026-01-20',
      note: 'Mobilization advance',
    ));
    await upsertPayment(Payment(
      projectId: projectId,
      type: PaymentType.receipt,
      amount: 150000,
      date: '2026-03-01',
      note: 'Milestone 1',
      dueDate: today,
    ));

    await _setSetting('demo_seeded', '1');
  }
}
