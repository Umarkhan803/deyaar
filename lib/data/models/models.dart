enum AppThemePreference {
  system,
  light,
  dark;

  String get label {
    switch (this) {
      case AppThemePreference.system:
        return 'System';
      case AppThemePreference.light:
        return 'Light';
      case AppThemePreference.dark:
        return 'Dark';
    }
  }

  static AppThemePreference fromString(String? value) {
    switch (value) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
        return AppThemePreference.dark;
      default:
        return AppThemePreference.system;
    }
  }
}

enum WageType {
  daily,
  contract;

  String get label {
    switch (this) {
      case WageType.daily:
        return 'Daily Wages';
      case WageType.contract:
        return 'Contract Base';
    }
  }
}

class Client {
  final int? id;
  final String name;
  final String phone;
  final String location;
  final double contractValue;
  final String notes;

  const Client({
    this.id,
    required this.name,
    this.phone = '',
    this.location = '',
    this.contractValue = 0,
    this.notes = '',
  });

  Client copyWith({
    int? id,
    String? name,
    String? phone,
    String? location,
    double? contractValue,
    String? notes,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      contractValue: contractValue ?? this.contractValue,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'location': location,
        'contract_value': contractValue,
        'notes': notes,
      };

  factory Client.fromMap(Map<String, Object?> map) => Client(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        location: map['location'] as String? ?? '',
        contractValue: (map['contract_value'] as num?)?.toDouble() ?? 0,
        notes: map['notes'] as String? ?? '',
      );
}

enum ProjectStatus {
  planning,
  ongoing,
  completed,
  hold;

  String get label {
    switch (this) {
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.ongoing:
        return 'Active';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.hold:
        return 'On Hold';
    }
  }

  static ProjectStatus fromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'planning':
        return ProjectStatus.planning;
      case 'completed':
        return ProjectStatus.completed;
      case 'hold':
        return ProjectStatus.hold;
      default:
        return ProjectStatus.ongoing;
    }
  }
}

class Project {
  final int? id;
  final int? clientId;
  final String name;
  final String startDate;
  final String expectedEnd;
  final double progress;
  final ProjectStatus status;
  final String? clientName;
  final String location;
  /// Covered area used for Cost of Construction quotes (sq ft).
  final double coveredAreaSft;
  /// Construction rate per sq ft.
  final double ratePerSft;
  /// Duration / notes line for the cost section.
  final String constructionDuration;

  const Project({
    this.id,
    this.clientId,
    required this.name,
    this.startDate = '',
    this.expectedEnd = '',
    this.progress = 0,
    this.status = ProjectStatus.planning,
    this.clientName,
    this.location = '',
    this.coveredAreaSft = 0,
    this.ratePerSft = 0,
    this.constructionDuration = '',
  });

  String get displayId => id == null ? 'PRJ-????' : 'PRJ-${id!.toString().padLeft(4, '0')}';

  double get totalConstructionCost => coveredAreaSft * ratePerSft;

  Project copyWith({
    int? id,
    int? clientId,
    String? name,
    String? startDate,
    String? expectedEnd,
    double? progress,
    ProjectStatus? status,
    String? clientName,
    String? location,
    double? coveredAreaSft,
    double? ratePerSft,
    String? constructionDuration,
  }) {
    return Project(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      expectedEnd: expectedEnd ?? this.expectedEnd,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      clientName: clientName ?? this.clientName,
      location: location ?? this.location,
      coveredAreaSft: coveredAreaSft ?? this.coveredAreaSft,
      ratePerSft: ratePerSft ?? this.ratePerSft,
      constructionDuration: constructionDuration ?? this.constructionDuration,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'client_id': clientId,
        'name': name,
        'start_date': startDate,
        'expected_end': expectedEnd,
        'progress': progress,
        'status': status.name,
        'location': location,
        'covered_area_sft': coveredAreaSft,
        'rate_per_sft': ratePerSft,
        'construction_duration': constructionDuration,
      };

  factory Project.fromMap(Map<String, Object?> map) => Project(
        id: map['id'] as int?,
        clientId: map['client_id'] as int?,
        name: map['name'] as String? ?? '',
        startDate: map['start_date'] as String? ?? '',
        expectedEnd: map['expected_end'] as String? ?? '',
        progress: (map['progress'] as num?)?.toDouble() ?? 0,
        status: ProjectStatus.fromString(map['status'] as String?),
        clientName: map['client_name'] as String?,
        location: map['location'] as String? ?? '',
        coveredAreaSft: (map['covered_area_sft'] as num?)?.toDouble() ?? 0,
        ratePerSft: (map['rate_per_sft'] as num?)?.toDouble() ?? 0,
        constructionDuration: map['construction_duration'] as String? ?? '',
      );
}

class ProjectMilestone {
  final int? id;
  final int projectId;
  final String title;
  final bool done;
  final String? completedAt;
  final int sortOrder;

  const ProjectMilestone({
    this.id,
    required this.projectId,
    required this.title,
    this.done = false,
    this.completedAt,
    this.sortOrder = 0,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'project_id': projectId,
        'title': title,
        'done': done ? 1 : 0,
        'completed_at': completedAt,
        'sort_order': sortOrder,
      };

  factory ProjectMilestone.fromMap(Map<String, Object?> map) => ProjectMilestone(
        id: map['id'] as int?,
        projectId: map['project_id'] as int? ?? 0,
        title: map['title'] as String? ?? '',
        done: (map['done'] as int? ?? 0) == 1,
        completedAt: map['completed_at'] as String?,
        sortOrder: map['sort_order'] as int? ?? 0,
      );

  static const defaultTitles = [
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
}

/// Admin-managed milestone templates shown on every project.
class AdminMilestone {
  final int? id;
  final String title;
  final int sortOrder;
  final String createdAt;

  const AdminMilestone({
    this.id,
    required this.title,
    this.sortOrder = 0,
    this.createdAt = '',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'sort_order': sortOrder,
        'created_at': createdAt,
      };

  factory AdminMilestone.fromMap(Map<String, Object?> map) => AdminMilestone(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        sortOrder: map['sort_order'] as int? ?? 0,
        createdAt: map['created_at'] as String? ?? '',
      );
}

class Worker {
  final int? id;
  final String name;
  final String phone;
  final String trade;
  final double dailyWageDefault;
  final String experience;
  final String address;
  final String notes;
  final String joiningDate;
  final double contractAmount;
  final WageType wageType;
  /// Assigned project ids (runtime / form; not a DB column on workers).
  final List<int> assignedProjectIds;

  const Worker({
    this.id,
    required this.name,
    this.phone = '',
    this.trade = '',
    this.dailyWageDefault = 0,
    this.experience = '',
    this.address = '',
    this.notes = '',
    this.joiningDate = '',
    this.contractAmount = 0,
    this.wageType = WageType.daily,
    this.assignedProjectIds = const [],
  });

  String get displayId {
    if (id == null) return 'EMP-????';
    final hex = id!.toRadixString(16).padLeft(4, '0');
    return 'EMP-$hex';
  }

  Worker copyWith({
    int? id,
    String? name,
    String? phone,
    String? trade,
    double? dailyWageDefault,
    String? experience,
    String? address,
    String? notes,
    String? joiningDate,
    double? contractAmount,
    WageType? wageType,
    List<int>? assignedProjectIds,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      trade: trade ?? this.trade,
      dailyWageDefault: dailyWageDefault ?? this.dailyWageDefault,
      experience: experience ?? this.experience,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      joiningDate: joiningDate ?? this.joiningDate,
      contractAmount: contractAmount ?? this.contractAmount,
      wageType: wageType ?? this.wageType,
      assignedProjectIds: assignedProjectIds ?? this.assignedProjectIds,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'trade': trade,
        'daily_wage_default': dailyWageDefault,
        'experience': experience,
        'address': address,
        'notes': notes,
        'joining_date': joiningDate,
        'contract_amount': contractAmount,
        'wage_type': wageType.name,
      };

  factory Worker.fromMap(Map<String, Object?> map) => Worker(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        trade: map['trade'] as String? ?? '',
        dailyWageDefault: (map['daily_wage_default'] as num?)?.toDouble() ?? 0,
        experience: map['experience'] as String? ?? '',
        address: map['address'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        joiningDate: map['joining_date'] as String? ?? '',
        contractAmount: (map['contract_amount'] as num?)?.toDouble() ?? 0,
        wageType: (map['wage_type'] as String?) == 'contract'
            ? WageType.contract
            : WageType.daily,
      );
}

enum AttendanceStatus {
  present,
  absent,
  half;

  String get short {
    switch (this) {
      case AttendanceStatus.present:
        return 'P';
      case AttendanceStatus.absent:
        return 'A';
      case AttendanceStatus.half:
        return 'H';
    }
  }

  static AttendanceStatus fromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'absent':
      case 'a':
        return AttendanceStatus.absent;
      case 'half':
      case 'h':
        return AttendanceStatus.half;
      default:
        return AttendanceStatus.present;
    }
  }
}

class Attendance {
  final int? id;
  final int workerId;
  final int? projectId;
  final String date;
  final AttendanceStatus status;
  final double wage;
  final double overtimeHours;
  final String? workerName;
  final String? projectName;

  const Attendance({
    this.id,
    required this.workerId,
    this.projectId,
    required this.date,
    this.status = AttendanceStatus.present,
    this.wage = 0,
    this.overtimeHours = 0,
    this.workerName,
    this.projectName,
  });

  bool get present => status == AttendanceStatus.present || status == AttendanceStatus.half;

  String get statusLabel {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.half:
        return 'Half day';
    }
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'worker_id': workerId,
        'project_id': projectId,
        'date': date,
        'status': status.name,
        'present': present ? 1 : 0,
        'wage': wage,
        'overtime_hours': overtimeHours,
      };

  factory Attendance.fromMap(Map<String, Object?> map) {
    final statusRaw = map['status'] as String?;
    AttendanceStatus status;
    if (statusRaw != null && statusRaw.isNotEmpty) {
      status = AttendanceStatus.fromString(statusRaw);
    } else {
      status = (map['present'] as int? ?? 1) == 1
          ? AttendanceStatus.present
          : AttendanceStatus.absent;
    }
    return Attendance(
      id: map['id'] as int?,
      workerId: map['worker_id'] as int? ?? 0,
      projectId: map['project_id'] as int?,
      date: map['date'] as String? ?? '',
      status: status,
      wage: (map['wage'] as num?)?.toDouble() ?? 0,
      overtimeHours: (map['overtime_hours'] as num?)?.toDouble() ?? 0,
      workerName: map['worker_name'] as String?,
      projectName: map['project_name'] as String?,
    );
  }
}

class WagePayment {
  final int? id;
  final int workerId;
  final double amount;
  final String date;
  final String note;
  final int? projectId;
  final String? workerName;
  final String? projectName;

  const WagePayment({
    this.id,
    required this.workerId,
    required this.amount,
    required this.date,
    this.note = '',
    this.projectId,
    this.workerName,
    this.projectName,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'worker_id': workerId,
        'amount': amount,
        'date': date,
        'note': note,
        'project_id': projectId,
      };

  factory WagePayment.fromMap(Map<String, Object?> map) => WagePayment(
        id: map['id'] as int?,
        workerId: map['worker_id'] as int? ?? 0,
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        date: map['date'] as String? ?? '',
        note: map['note'] as String? ?? '',
        projectId: map['project_id'] as int?,
        workerName: map['worker_name'] as String?,
        projectName: map['project_name'] as String?,
      );
}

class WagePaymentPhoto {
  final int? id;
  final int wagePaymentId;
  final String path;
  final String caption;
  final String takenAt;

  const WagePaymentPhoto({
    this.id,
    required this.wagePaymentId,
    required this.path,
    this.caption = '',
    required this.takenAt,
  });

  WagePaymentPhoto copyWith({
    int? id,
    int? wagePaymentId,
    String? path,
    String? caption,
    String? takenAt,
  }) {
    return WagePaymentPhoto(
      id: id ?? this.id,
      wagePaymentId: wagePaymentId ?? this.wagePaymentId,
      path: path ?? this.path,
      caption: caption ?? this.caption,
      takenAt: takenAt ?? this.takenAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'wage_payment_id': wagePaymentId,
        'path': path,
        'caption': caption,
        'taken_at': takenAt,
      };

  factory WagePaymentPhoto.fromMap(Map<String, Object?> map) => WagePaymentPhoto(
        id: map['id'] as int?,
        wagePaymentId: map['wage_payment_id'] as int? ?? 0,
        path: map['path'] as String? ?? '',
        caption: map['caption'] as String? ?? '',
        takenAt: map['taken_at'] as String? ?? '',
      );
}

class ClientPayment {
  final int? id;
  final int clientId;
  final double amount;
  final String date;
  final String note;
  final String? clientName;

  const ClientPayment({
    this.id,
    required this.clientId,
    required this.amount,
    required this.date,
    this.note = '',
    this.clientName,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'client_id': clientId,
        'amount': amount,
        'date': date,
        'note': note,
      };

  factory ClientPayment.fromMap(Map<String, Object?> map) => ClientPayment(
        id: map['id'] as int?,
        clientId: map['client_id'] as int? ?? 0,
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        date: map['date'] as String? ?? '',
        note: map['note'] as String? ?? '',
        clientName: map['client_name'] as String?,
      );
}

enum StockMaterial {
  cement,
  steel,
  sand,
  bricks,
  tiles,
  paint,
  other;

  String get label {
    switch (this) {
      case StockMaterial.cement:
        return 'Cement';
      case StockMaterial.steel:
        return 'Steel';
      case StockMaterial.sand:
        return 'Sand';
      case StockMaterial.bricks:
        return 'Bricks';
      case StockMaterial.tiles:
        return 'Tiles';
      case StockMaterial.paint:
        return 'Paint';
      case StockMaterial.other:
        return 'Other';
    }
  }

  static StockMaterial fromString(String? value) {
    return StockMaterial.values.firstWhere(
      (e) => e.name == (value ?? '').toLowerCase(),
      orElse: () => StockMaterial.other,
    );
  }
}

class Supplier {
  final int? id;
  final String name;
  final String phone;
  final String notes;

  const Supplier({
    this.id,
    required this.name,
    this.phone = '',
    this.notes = '',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'notes': notes,
      };

  factory Supplier.fromMap(Map<String, Object?> map) => Supplier(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
      );
}

class MaterialItem {
  final int? id;
  final int? projectId;
  final StockMaterial type;
  final String name;
  final double qtyPurchased;
  final double qtyUsed;
  final String unit;
  final double cost;
  final double openingStock;
  final double lowStockAlert;
  final double purchasePrice;
  final int? supplierId;
  final String remarks;
  final String? projectName;
  final String? supplierName;

  const MaterialItem({
    this.id,
    this.projectId,
    required this.type,
    this.name = '',
    this.qtyPurchased = 0,
    this.qtyUsed = 0,
    this.unit = '',
    this.cost = 0,
    this.openingStock = 0,
    this.lowStockAlert = 0,
    this.purchasePrice = 0,
    this.supplierId,
    this.remarks = '',
    this.projectName,
    this.supplierName,
  });

  String get displayName => name.isNotEmpty ? name : type.label;

  double get remaining =>
      ((openingStock > 0 ? openingStock : qtyPurchased) - qtyUsed).clamp(0, double.infinity);

  Map<String, Object?> toMap() => {
        'id': id,
        'project_id': projectId,
        'type': type.name,
        'name': name,
        'qty_purchased': qtyPurchased,
        'qty_used': qtyUsed,
        'unit': unit,
        'cost': cost,
        'opening_stock': openingStock,
        'low_stock_alert': lowStockAlert,
        'purchase_price': purchasePrice,
        'supplier_id': supplierId,
        'remarks': remarks,
      };

  factory MaterialItem.fromMap(Map<String, Object?> map) => MaterialItem(
        id: map['id'] as int?,
        projectId: map['project_id'] as int?,
        type: StockMaterial.fromString(map['type'] as String?),
        name: map['name'] as String? ?? '',
        qtyPurchased: (map['qty_purchased'] as num?)?.toDouble() ?? 0,
        qtyUsed: (map['qty_used'] as num?)?.toDouble() ?? 0,
        unit: map['unit'] as String? ?? '',
        cost: (map['cost'] as num?)?.toDouble() ?? 0,
        openingStock: (map['opening_stock'] as num?)?.toDouble() ?? 0,
        lowStockAlert: (map['low_stock_alert'] as num?)?.toDouble() ?? 0,
        purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
        supplierId: map['supplier_id'] as int?,
        remarks: map['remarks'] as String? ?? '',
        projectName: map['project_name'] as String?,
        supplierName: map['supplier_name'] as String?,
      );
}

enum ExpenseCategory {
  labour,
  material,
  transport,
  misc;

  String get label {
    switch (this) {
      case ExpenseCategory.labour:
        return 'Labour';
      case ExpenseCategory.material:
        return 'Material';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.misc:
        return 'Miscellaneous';
    }
  }

  static ExpenseCategory fromString(String? value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == (value ?? '').toLowerCase(),
      orElse: () => ExpenseCategory.misc,
    );
  }
}

class Expense {
  final int? id;
  final int? projectId;
  final ExpenseCategory category;
  final double amount;
  final String date;
  final String note;
  final String? projectName;

  const Expense({
    this.id,
    this.projectId,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
    this.projectName,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'project_id': projectId,
        'category': category.name,
        'amount': amount,
        'date': date,
        'note': note,
      };

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
        id: map['id'] as int?,
        projectId: map['project_id'] as int?,
        category: ExpenseCategory.fromString(map['category'] as String?),
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        date: map['date'] as String? ?? '',
        note: map['note'] as String? ?? '',
        projectName: map['project_name'] as String?,
      );
}

enum PaymentType {
  advance,
  receipt;

  String get label => this == PaymentType.advance ? 'Advance' : 'Receipt';

  static PaymentType fromString(String? value) {
    return value == 'advance' ? PaymentType.advance : PaymentType.receipt;
  }
}

class Payment {
  final int? id;
  final int projectId;
  final PaymentType type;
  final double amount;
  final String date;
  final String note;
  final String? dueDate;
  final String? projectName;

  const Payment({
    this.id,
    required this.projectId,
    required this.type,
    required this.amount,
    required this.date,
    this.note = '',
    this.dueDate,
    this.projectName,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'project_id': projectId,
        'type': type.name,
        'amount': amount,
        'date': date,
        'note': note,
        'due_date': dueDate,
      };

  factory Payment.fromMap(Map<String, Object?> map) => Payment(
        id: map['id'] as int?,
        projectId: map['project_id'] as int? ?? 0,
        type: PaymentType.fromString(map['type'] as String?),
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        date: map['date'] as String? ?? '',
        note: map['note'] as String? ?? '',
        dueDate: map['due_date'] as String?,
        projectName: map['project_name'] as String?,
      );
}

class Quotation {
  final int? id;
  final String title;
  final String createdAt;
  final String updatedAt;

  const Quotation({
    this.id,
    required this.title,
    this.createdAt = '',
    this.updatedAt = '',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Quotation.fromMap(Map<String, Object?> map) => Quotation(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        createdAt: map['created_at'] as String? ?? '',
        updatedAt: map['updated_at'] as String? ?? '',
      );
}

class BillItem {
  final int? id;
  final int? billId;
  final String description;
  final String unit;
  final double qty;
  final double rate;
  final int sortOrder;

  const BillItem({
    this.id,
    this.billId,
    this.description = '',
    this.unit = '',
    this.qty = 0,
    this.rate = 0,
    this.sortOrder = 0,
  });

  double get amount => qty * rate;

  Map<String, Object?> toMap() => {
        'id': id,
        'bill_id': billId,
        'description': description,
        'unit': unit,
        'qty': qty,
        'rate': rate,
        'sort_order': sortOrder,
      };

  factory BillItem.fromMap(Map<String, Object?> map) => BillItem(
        id: map['id'] as int?,
        billId: map['bill_id'] as int?,
        description: map['description'] as String? ?? '',
        unit: map['unit'] as String? ?? '',
        qty: (map['qty'] as num?)?.toDouble() ?? 0,
        rate: (map['rate'] as num?)?.toDouble() ?? 0,
        sortOrder: map['sort_order'] as int? ?? 0,
      );

  BillItem copyWith({
    int? id,
    int? billId,
    String? description,
    String? unit,
    double? qty,
    double? rate,
    int? sortOrder,
  }) =>
      BillItem(
        id: id ?? this.id,
        billId: billId ?? this.billId,
        description: description ?? this.description,
        unit: unit ?? this.unit,
        qty: qty ?? this.qty,
        rate: rate ?? this.rate,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}

class Bill {
  final int? id;
  final String name;
  final String note;
  final String createdAt;
  final String updatedAt;
  final List<BillItem> items;

  const Bill({
    this.id,
    required this.name,
    this.note = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.items = const [],
  });

  double get totalAmount =>
      items.fold<double>(0, (sum, item) => sum + item.amount);

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'note': note,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Bill.fromMap(Map<String, Object?> map, {List<BillItem> items = const []}) =>
      Bill(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        note: map['note'] as String? ?? '',
        createdAt: map['created_at'] as String? ?? '',
        updatedAt: map['updated_at'] as String? ?? '',
        items: items,
      );

  Bill copyWith({
    int? id,
    String? name,
    String? note,
    String? createdAt,
    String? updatedAt,
    List<BillItem>? items,
  }) =>
      Bill(
        id: id ?? this.id,
        name: name ?? this.name,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        items: items ?? this.items,
      );
}

/// Admin-managed Cost of Construction line (key = label, value supports placeholders).
/// Placeholders: `{area}`, `{rate}`, `{total}`, `{duration}`, `{project}`.
class CostConstructionItem {
  final int? id;
  final String label;
  final String value;
  final int sortOrder;
  final String createdAt;

  const CostConstructionItem({
    this.id,
    required this.label,
    this.value = '',
    this.sortOrder = 0,
    this.createdAt = '',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'label': label,
        'value': value,
        'sort_order': sortOrder,
        'created_at': createdAt,
      };

  factory CostConstructionItem.fromMap(Map<String, Object?> map) =>
      CostConstructionItem(
        id: map['id'] as int?,
        label: map['label'] as String? ?? '',
        value: map['value'] as String? ?? '',
        sortOrder: map['sort_order'] as int? ?? 0,
        createdAt: map['created_at'] as String? ?? '',
      );

  /// Resolves placeholders from project size / rate / duration.
  String resolveValue({
    required double areaSft,
    required double ratePerSft,
    required String duration,
    String projectName = '',
  }) {
    final total = areaSft * ratePerSft;
    final areaStr = areaSft == areaSft.roundToDouble()
        ? areaSft.toStringAsFixed(0)
        : areaSft.toStringAsFixed(2);
    final rateStr = ratePerSft == ratePerSft.roundToDouble()
        ? ratePerSft.toStringAsFixed(0)
        : ratePerSft.toStringAsFixed(2);
    final totalStr = _indianRs(total);
    return value
        .replaceAll('{area}', areaStr)
        .replaceAll('{rate}', rateStr)
        .replaceAll('{total}', totalStr)
        .replaceAll('{duration}', duration.isEmpty ? '—' : duration)
        .replaceAll('{project}', projectName.isEmpty ? '—' : projectName);
  }

  static String _indianRs(double amount) {
    final n = amount.round();
    final s = n.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }
}

class SitePhoto {
  final int? id;
  final int projectId;
  final String path;
  final String caption;
  final String takenAt;

  const SitePhoto({
    this.id,
    required this.projectId,
    required this.path,
    this.caption = '',
    required this.takenAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'project_id': projectId,
        'path': path,
        'caption': caption,
        'taken_at': takenAt,
      };

  factory SitePhoto.fromMap(Map<String, Object?> map) => SitePhoto(
        id: map['id'] as int?,
        projectId: map['project_id'] as int? ?? 0,
        path: map['path'] as String? ?? '',
        caption: map['caption'] as String? ?? '',
        takenAt: map['taken_at'] as String? ?? '',
      );
}

class AppSettings {
  final String companyName;
  final String? pinHash;
  final String currency;
  final bool demoSeeded;
  final AppThemePreference themeMode;
  final bool biometricEnabled;

  const AppSettings({
    this.companyName = 'Deyaar Constructions',
    this.pinHash,
    this.currency = 'INR',
    this.demoSeeded = false,
    this.themeMode = AppThemePreference.system,
    this.biometricEnabled = false,
  });

  AppSettings copyWith({
    String? companyName,
    String? pinHash,
    String? currency,
    bool? demoSeeded,
    AppThemePreference? themeMode,
    bool? biometricEnabled,
    bool clearPin = false,
  }) {
    return AppSettings(
      companyName: companyName ?? this.companyName,
      pinHash: clearPin ? null : (pinHash ?? this.pinHash),
      currency: currency ?? this.currency,
      demoSeeded: demoSeeded ?? this.demoSeeded,
      themeMode: themeMode ?? this.themeMode,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}

class DashboardStats {
  final int totalProjects;
  final int ongoingProjects;
  final int completedProjects;
  final double pendingPayments;
  final double totalReceived;
  final double totalExpenses;

  const DashboardStats({
    this.totalProjects = 0,
    this.ongoingProjects = 0,
    this.completedProjects = 0,
    this.pendingPayments = 0,
    this.totalReceived = 0,
    this.totalExpenses = 0,
  });

  double get profitLoss => totalReceived - totalExpenses;
}

class DataOverview {
  final int workers;
  final int attendance;
  final int materials;
  final int paymentsAndExpenses;
  final int sitePhotos;
  final int suppliers;
  final int projects;
  final int clients;

  const DataOverview({
    this.workers = 0,
    this.attendance = 0,
    this.materials = 0,
    this.paymentsAndExpenses = 0,
    this.sitePhotos = 0,
    this.suppliers = 0,
    this.projects = 0,
    this.clients = 0,
  });
}
