import 'package:flutter/material.dart';

import '../data/models/models.dart';
import '../data/repositories/app_repository.dart';
import '../theme/app_theme.dart';

class AppProvider extends ChangeNotifier {
  final AppRepository repo;
  AppProvider(this.repo);

  bool loading = true;
  bool unlocked = false;
  AppSettings settings = const AppSettings();
  DashboardStats stats = const DashboardStats();
  List<Client> clients = [];
  List<Project> projects = [];
  List<Worker> workers = [];
  List<Attendance> attendance = [];
  List<WagePayment> wagePayments = [];
  List<MaterialItem> materials = [];
  List<Expense> expenses = [];
  List<Payment> payments = [];
  List<Payment> reminders = [];
  List<Supplier> suppliers = [];
  List<Quotation> quotations = [];
  List<AdminMilestone> adminMilestones = [];
  List<CostConstructionItem> costConstructionItems = [];
  Map<String, double> monthlyExpenses = {};

  ThemeMode get themeMode => AppTheme.themeModeFromString(settings.themeMode.name);

  Future<void> init() async {
    loading = true;
    notifyListeners();
    await repo.seedDemoIfNeeded();
    settings = await repo.getSettings();
    unlocked = !(await repo.hasPin);
    await refreshAll();
    loading = false;
    notifyListeners();
  }

  Future<bool> unlock(String pin) async {
    final ok = await repo.verifyPin(pin);
    if (ok) {
      unlocked = true;
      notifyListeners();
    }
    return ok;
  }

  void unlockBiometric() {
    unlocked = true;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    settings = await repo.getSettings();
    stats = await repo.getDashboardStats();
    clients = await repo.getClients();
    projects = await repo.getProjects();
    workers = await repo.getWorkers();
    attendance = await repo.getAttendance();
    wagePayments = await repo.getWagePayments();
    materials = await repo.getMaterials();
    expenses = await repo.getExpenses();
    payments = await repo.getPayments();
    reminders = await repo.getPaymentReminders();
    suppliers = await repo.getSuppliers();
    quotations = await repo.getQuotations();
    adminMilestones = await repo.getAdminMilestones();
    costConstructionItems = await repo.getCostConstructionItems();
    monthlyExpenses = await repo.monthlyExpensesLast6();
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    stats = await repo.getDashboardStats();
    reminders = await repo.getPaymentReminders();
    monthlyExpenses = await repo.monthlyExpensesLast6();
    notifyListeners();
  }

  Future<void> saveClient(Client c) async {
    await repo.upsertClient(c);
    clients = await repo.getClients();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> removeClient(int id) async {
    await repo.deleteClient(id);
    clients = await repo.getClients();
    projects = await repo.getProjects();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> saveProject(Project p) async {
    await repo.upsertProject(p);
    projects = await repo.getProjects();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> removeProject(int id) async {
    await repo.deleteProject(id);
    projects = await repo.getProjects();
    materials = await repo.getMaterials();
    expenses = await repo.getExpenses();
    payments = await repo.getPayments();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> saveWorker(Worker w, {List<int>? projectIds}) async {
    await repo.upsertWorker(
      w,
      projectIds: projectIds ?? w.assignedProjectIds,
    );
    workers = await repo.getWorkers();
    notifyListeners();
  }

  Future<void> removeWorker(int id) async {
    await repo.deleteWorker(id);
    workers = await repo.getWorkers();
    attendance = await repo.getAttendance();
    wagePayments = await repo.getWagePayments();
    notifyListeners();
  }

  Future<void> saveAttendance(Attendance a) async {
    await repo.upsertAttendance(a);
    attendance = await repo.getAttendance();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> removeAttendance(int id) async {
    await repo.deleteAttendance(id);
    attendance = await repo.getAttendance();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> saveWagePayment(WagePayment p) async {
    await repo.upsertWagePayment(p);
    wagePayments = await repo.getWagePayments();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> removeWagePayment(int id) async {
    await repo.deleteWagePayment(id);
    wagePayments = await repo.getWagePayments();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> saveMaterial(MaterialItem m) async {
    await repo.upsertMaterial(m);
    materials = await repo.getMaterials();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> removeMaterial(int id) async {
    await repo.deleteMaterial(id);
    materials = await repo.getMaterials();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> saveSupplier(Supplier s) async {
    await repo.upsertSupplier(s);
    suppliers = await repo.getSuppliers();
    notifyListeners();
  }

  Future<void> removeSupplier(int id) async {
    await repo.deleteSupplier(id);
    suppliers = await repo.getSuppliers();
    materials = await repo.getMaterials();
    notifyListeners();
  }

  Future<void> saveQuotation(Quotation q) async {
    await repo.upsertQuotation(q);
    quotations = await repo.getQuotations();
    notifyListeners();
  }

  Future<void> removeQuotation(int id) async {
    await repo.deleteQuotation(id);
    quotations = await repo.getQuotations();
    notifyListeners();
  }

  Future<void> saveAdminMilestone(AdminMilestone m) async {
    await repo.upsertAdminMilestone(m);
    adminMilestones = await repo.getAdminMilestones();
    notifyListeners();
  }

  Future<void> removeAdminMilestone(int id) async {
    await repo.deleteAdminMilestone(id);
    adminMilestones = await repo.getAdminMilestones();
    notifyListeners();
  }

  Future<void> saveCostConstructionItem(CostConstructionItem item) async {
    await repo.upsertCostConstructionItem(item);
    costConstructionItems = await repo.getCostConstructionItems();
    notifyListeners();
  }

  Future<void> removeCostConstructionItem(int id) async {
    await repo.deleteCostConstructionItem(id);
    costConstructionItems = await repo.getCostConstructionItems();
    notifyListeners();
  }

  Future<void> saveExpense(Expense e) async {
    await repo.upsertExpense(e);
    expenses = await repo.getExpenses();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> removeExpense(int id) async {
    await repo.deleteExpense(id);
    expenses = await repo.getExpenses();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> savePayment(Payment p) async {
    await repo.upsertPayment(p);
    payments = await repo.getPayments();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> removePayment(int id) async {
    await repo.deletePayment(id);
    payments = await repo.getPayments();
    await refreshDashboard();
    notifyListeners();
  }

  Future<void> saveCompanyName(String name) async {
    await repo.updateCompanyName(name);
    settings = await repo.getSettings();
    notifyListeners();
  }

  Future<void> saveCurrency(String currency) async {
    await repo.updateCurrency(currency);
    settings = await repo.getSettings();
    notifyListeners();
  }

  Future<void> saveThemeMode(AppThemePreference mode) async {
    await repo.updateThemeMode(mode);
    settings = await repo.getSettings();
    notifyListeners();
  }

  Future<void> saveBiometricEnabled(bool enabled) async {
    await repo.updateBiometricEnabled(enabled);
    settings = await repo.getSettings();
    notifyListeners();
  }

  Future<void> savePin(String pin) async {
    await repo.setPin(pin);
    settings = await repo.getSettings();
    notifyListeners();
  }

  Future<void> removePin() async {
    await repo.clearPin();
    settings = await repo.getSettings();
    notifyListeners();
  }

  Future<void> eraseAllData() async {
    await repo.eraseAllData();
    await refreshAll();
  }
}
