import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'deyaar_constructions.db');
    return openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await _createV1(db);
        await _upgradeToV2(db);
        await _upgradeToV3(db);
        await _upgradeToV4(db);
        await _upgradeToV5(db);
        await _upgradeToV6(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _upgradeToV2(db);
        if (oldVersion < 3) await _upgradeToV3(db);
        if (oldVersion < 4) await _upgradeToV4(db);
        if (oldVersion < 5) await _upgradeToV5(db);
        if (oldVersion < 6) await _upgradeToV6(db);
      },
    );
  }

  Future<void> _createV1(Database db) async {
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        location TEXT NOT NULL DEFAULT '',
        contract_value REAL NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL DEFAULT '',
        expected_end TEXT NOT NULL DEFAULT '',
        progress REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'ongoing',
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE workers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        daily_wage_default REAL NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        worker_id INTEGER NOT NULL,
        project_id INTEGER,
        date TEXT NOT NULL,
        present INTEGER NOT NULL DEFAULT 1,
        wage REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (worker_id) REFERENCES workers(id) ON DELETE CASCADE,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE wage_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        worker_id INTEGER NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (worker_id) REFERENCES workers(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER,
        type TEXT NOT NULL,
        qty_purchased REAL NOT NULL DEFAULT 0,
        qty_used REAL NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT '',
        cost REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER,
        category TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        due_date TEXT,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE site_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        path TEXT NOT NULL,
        caption TEXT NOT NULL DEFAULT '',
        taken_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.insert('settings', {
      'key': 'company_name',
      'value': 'Deyaar Constructions',
    });
    await db.insert('settings', {'key': 'currency', 'value': 'INR'});
    await db.insert('settings', {'key': 'demo_seeded', 'value': '0'});
  }

  Future<void> _upgradeToV2(Database db) async {
    Future<void> tryExec(String sql) async {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    await tryExec("ALTER TABLE projects ADD COLUMN location TEXT NOT NULL DEFAULT ''");
    await tryExec("ALTER TABLE workers ADD COLUMN phone TEXT NOT NULL DEFAULT ''");
    await tryExec("ALTER TABLE workers ADD COLUMN trade TEXT NOT NULL DEFAULT ''");
    await tryExec("ALTER TABLE workers ADD COLUMN experience TEXT NOT NULL DEFAULT ''");
    await tryExec("ALTER TABLE workers ADD COLUMN address TEXT NOT NULL DEFAULT ''");
    await tryExec("ALTER TABLE workers ADD COLUMN joining_date TEXT NOT NULL DEFAULT ''");
    await tryExec("ALTER TABLE attendance ADD COLUMN status TEXT NOT NULL DEFAULT 'present'");
    await tryExec('ALTER TABLE wage_payments ADD COLUMN project_id INTEGER');
    await tryExec("ALTER TABLE materials ADD COLUMN name TEXT NOT NULL DEFAULT ''");
    await tryExec('ALTER TABLE materials ADD COLUMN opening_stock REAL NOT NULL DEFAULT 0');
    await tryExec('ALTER TABLE materials ADD COLUMN low_stock_alert REAL NOT NULL DEFAULT 0');
    await tryExec('ALTER TABLE materials ADD COLUMN purchase_price REAL NOT NULL DEFAULT 0');
    await tryExec('ALTER TABLE materials ADD COLUMN supplier_id INTEGER');
    await tryExec("ALTER TABLE materials ADD COLUMN remarks TEXT NOT NULL DEFAULT ''");

    await tryExec('''
      CREATE TABLE IF NOT EXISTS project_milestones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await tryExec('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.insert(
      'settings',
      {'key': 'theme_mode', 'value': 'system'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await db.insert(
      'settings',
      {'key': 'biometric_enabled', 'value': '0'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // Backfill attendance status from present flag
    await tryExec(
      "UPDATE attendance SET status = CASE WHEN present = 1 THEN 'present' ELSE 'absent' END WHERE status IS NULL OR status = ''",
    );
  }

  Future<void> _upgradeToV3(Database db) async {
    Future<void> tryExec(String sql) async {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    await tryExec('''
      CREATE TABLE IF NOT EXISTS worker_projects (
        worker_id INTEGER NOT NULL,
        project_id INTEGER NOT NULL,
        PRIMARY KEY (worker_id, project_id),
        FOREIGN KEY (worker_id) REFERENCES workers(id) ON DELETE CASCADE,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await tryExec(
      'ALTER TABLE attendance ADD COLUMN overtime_hours REAL NOT NULL DEFAULT 0',
    );
  }

  Future<void> _upgradeToV4(Database db) async {
    Future<void> tryExec(String sql) async {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    await tryExec('''
      CREATE TABLE IF NOT EXISTS quotations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<void> _upgradeToV5(Database db) async {
    Future<void> tryExec(String sql) async {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    await tryExec('''
      CREATE TABLE IF NOT EXISTS admin_milestones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT ''
      )
    ''');

    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM admin_milestones'),
        ) ??
        0;
    if (count == 0) {
      const defaults = [
        'Foundation',
        'Columns',
        'Roof',
        'Plastering',
        'Flooring',
        'Painting',
        'Electrical',
        'Plumbing',
        'Finishing',
      ];
      var i = 0;
      for (final title in defaults) {
        await db.insert('admin_milestones', {
          'title': title,
          'sort_order': i++,
          'created_at': '',
        });
      }
    }
  }

  Future<void> _upgradeToV6(Database db) async {
    Future<void> tryExec(String sql) async {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    await tryExec(
      'ALTER TABLE projects ADD COLUMN covered_area_sft REAL NOT NULL DEFAULT 0',
    );
    await tryExec(
      'ALTER TABLE projects ADD COLUMN rate_per_sft REAL NOT NULL DEFAULT 0',
    );
    await tryExec(
      "ALTER TABLE projects ADD COLUMN construction_duration TEXT NOT NULL DEFAULT ''",
    );

    await tryExec('''
      CREATE TABLE IF NOT EXISTS cost_construction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL,
        value TEXT NOT NULL DEFAULT '',
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT ''
      )
    ''');

    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM cost_construction_items'),
        ) ??
        0;
    if (count == 0) {
      const seeds = [
        (
          'Total covered Area of SF (as per working plan)',
          '600 sft',
        ),
        (
          'Covered Area Rate for Framed structure for SF',
          '600 sft',
        ),
        (
          'Cost of Construction /sft',
          'Rs. 2200/-',
        ),
        (
          'Total cost of construction',
          'Rs. 13,20,000/-',
        ),
      ];
      var i = 0;
      for (final s in seeds) {
        await db.insert('cost_construction_items', {
          'label': s.$1,
          'value': s.$2,
          'sort_order': i++,
          'created_at': '',
        });
      }
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
