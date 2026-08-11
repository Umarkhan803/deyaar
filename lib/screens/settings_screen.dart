import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/form_actions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DataOverview? _overview;
  final _company = TextEditingController();
  final _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _company.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final app = context.read<AppProvider>();
    _company.text = app.settings.companyName;
    final overview = await app.repo.getDataOverview();
    if (mounted) setState(() => _overview = overview);
  }

  Future<void> _importCsv() async {
    final contentCtrl = TextEditingController();
    final pasted = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste CSV'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: contentCtrl,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText:
                  'Clients: name,phone,location,contract_value,notes\nWorkers: name,phone,trade,daily_wages,experience,address,notes',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, contentCtrl.text), child: const Text('Continue')),
        ],
      ),
    );
    if (pasted == null || pasted.trim().isEmpty || !mounted) return;

    final type = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import CSV as'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'clients'), child: const Text('Clients')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'workers'), child: const Text('Workers')),
        ],
      ),
    );
    if (type == null || !mounted) return;
    final rows = csv.decode(pasted);
    final imported = await context.read<AppProvider>().repo.importCsvRows(rows: rows, type: type);
    await context.read<AppProvider>().refreshAll();
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported ${imported.clients} clients, ${imported.workers} workers')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final o = _overview;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Data Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _row('Workers', '${o?.workers ?? '…'}'),
                _row('Attendance records', '${o?.attendance ?? '…'}'),
                _row('Materials', '${o?.materials ?? '…'}'),
                _row('Payments & expenses', '${o?.paymentsAndExpenses ?? '…'}'),
                _row('Site photos', '${o?.sitePhotos ?? '…'}'),
                _row('Suppliers', '${o?.suppliers ?? '…'}'),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: AppColors.danger),
                  title: const Text('Erase all data', style: TextStyle(color: AppColors.danger)),
                  subtitle: const Text('Deletes every record on this device.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Erase all data?'),
                        content: const Text('This cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Erase')),
                        ],
                      ),
                    );
                    if (ok == true && mounted) {
                      await app.eraseAllData();
                      await _reload();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Company', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(controller: _company, decoration: const InputDecoration(labelText: 'Company name')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: app.settings.currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: const [
                      DropdownMenuItem(value: 'INR', child: Text('INR')),
                      DropdownMenuItem(value: 'QAR', child: Text('QAR')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                    ],
                    onChanged: (v) async {
                      if (v != null) await app.saveCurrency(v);
                    },
                  ),
                  const SizedBox(height: 12),
                  FormActions(
                    primaryLabel: 'Save',
                    onPrimary: () async {
                      await app.saveCompanyName(_company.text.trim());
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.dark_mode_outlined),
                    title: Text('Theme'),
                    subtitle: Text('Follows the device light/dark setting when System is selected'),
                  ),
                  SegmentedButton<AppThemePreference>(
                    segments: const [
                      ButtonSegment(value: AppThemePreference.system, label: Text('System')),
                      ButtonSegment(value: AppThemePreference.light, label: Text('Light')),
                      ButtonSegment(value: AppThemePreference.dark, label: Text('Dark')),
                    ],
                    selected: {app.settings.themeMode},
                    onSelectionChanged: (s) => app.saveThemeMode(s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Security', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Fingerprint unlock'),
                  subtitle: const Text('Use biometrics when available; PIN remains as backup'),
                  value: app.settings.biometricEnabled,
                  onChanged: (v) async {
                    if (v) {
                      final can = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
                      if (!can) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Biometrics not available on this device')),
                          );
                        }
                        return;
                      }
                    }
                    await app.saveBiometricEnabled(v);
                  },
                ),
                ListTile(
                  title: const Text('Set / update PIN'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _setPin(context),
                ),
                if (app.settings.pinHash != null)
                  ListTile(
                    title: const Text('Remove PIN'),
                    onTap: () => app.removePin(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Data import', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import CSV'),
              subtitle: const Text('Paste CSV text to import clients or workers'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _importCsv,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(
                      'assets/brand/logo.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.apartment, size: 48, color: AppColors.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('DEYAAR CONSTRUCTIONS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const Text('Building Your Vision', style: TextStyle(color: AppColors.primaryBlue)),
                  const SizedBox(height: 8),
                  Text('Version 1.0 (build 1)', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    'Works fully offline — all data stays on this device',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text('© 2026 Deyaar Constructions', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Future<void> _setPin(BuildContext context) async {
    final pin = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set PIN'),
        content: TextField(
          controller: pin,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: '4–6 digit PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && pin.text.trim().length >= 4) {
      await context.read<AppProvider>().savePin(pin.text.trim());
    }
  }
}
