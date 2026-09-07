import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ClientViewScreen extends StatefulWidget {
  final int clientId;
  const ClientViewScreen({super.key, required this.clientId});

  @override
  State<ClientViewScreen> createState() => _ClientViewScreenState();
}

class _ClientViewScreenState extends State<ClientViewScreen> {
  Client? _client;
  List<ClientPayment> _payments = [];
  double _totalPaid = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final app = context.read<AppProvider>();
    final client = await app.repo.getClient(widget.clientId);
    final payments = await app.repo.getClientPayments(clientId: widget.clientId);
    double totalPaid = await app.repo.getClientTotalPaid(widget.clientId);

    if (!mounted) return;
    setState(() {
      _client = client;
      _payments = payments;
      _totalPaid = totalPaid;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _client == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final client = _client!;
    final balance = client.contractValue - _totalPaid;
    final currency = context.watch<AppProvider>().settings.currency;

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editClient(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            onPressed: () => _deleteClient(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoRow(Icons.person_outline, 'Phone', client.phone),
            const Divider(height: 24),
            _buildInfoRow(Icons.place_outlined, 'Location', client.location.isEmpty ? 'Not provided' : client.location),
            const Divider(height: 24),
            _buildInfoRow(Icons.notes_outlined, 'Notes', client.notes.isEmpty ? 'Not provided' : client.notes),
            const Divider(height: 24),
            // Contract value and balance display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAmountRow(Icons.attach_money, 'Contract Value', Formatters.money(client.contractValue, currency: currency)),
                    const SizedBox(height: 12),
                    _buildAmountRow(Icons.account_balance_wallet, 'Balance Due', Formatters.money(balance, currency: currency),
                        color: balance < 0 ? Colors.green : (balance > 0 ? Colors.red : Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _recordPayment(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add),
                  const SizedBox(width: 8),
                  const Text('Record Payment'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            _buildPaymentHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: AppColors.textMuted(context)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: AppColors.textMuted(context)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editClient(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Edit Client')),
          body: ClientForm(client: _client),
        ),
      ),
    );
    if (mounted) await _loadData();
  }

  Future<void> _recordPayment(BuildContext context) async {
    final amount = TextEditingController();
    final date = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final note = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount paid',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: date,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        date.text = picked.toString().split(' ')[0];
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g., Advance payment, Installment 1',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      if (amount.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an amount')),
        );
        return;
      }

      final app = context.read<AppProvider>();
      final payment = ClientPayment(
        clientId: widget.clientId,
        amount: double.parse(amount.text),
        date: date.text,
        note: note.text,
      );

      try {
        await app.repo.upsertClientPayment(payment);
        if (mounted) {
          await _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment recorded successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error recording payment: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteClient(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Client'),
          content: const Text('Are you sure you want to delete this client? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    // Handle null case explicitly - if user dismisses dialog, confirmed is null
    if (confirmed != null && confirmed && mounted) {
      await context.read<AppProvider>().removeClient(_client!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client deleted successfully')),
        );
        // Navigate back to clients screen
        if (context.mounted) Navigator.of(context).pop();
      }
    }
  }

  Widget _buildPaymentHistory() {
    if (_payments.isEmpty) {
      final textStyle = TextStyle(color: AppColors.textMuted(context));
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No payments recorded yet.',
          style: textStyle,
          textAlign: TextAlign.center,
        ),
      );
    }

    final currency = context.watch<AppProvider>().settings.currency;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _payments.length,
      separatorBuilder: (_, __) => const Divider(height: 12),
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return ListTile(
          leading: Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text(
            Formatters.money(payment.amount, currency: currency),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(Formatters.dateDisplay(payment.date)),
              if (payment.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(payment.note, style: TextStyle(color: AppColors.textMuted(context))),
              ],
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deletePayment(payment.id!),
          ),
        );
      },
    );
  }

  Future<void> _deletePayment(int paymentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this payment record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<AppProvider>().repo.deleteClientPayment(paymentId);
        if (mounted) {
          await _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting payment: $e')),
          );
        }
      }
    }
  }
}

// Reuse the client form from clients_screen.dart but make it read-only? Actually we'll use the same form for editing.
class ClientForm extends StatefulWidget {
  final Client? client;
  const ClientForm({super.key, this.client});

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _contract = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.client != null) {
      _name.text = widget.client!.name;
      _phone.text = widget.client!.phone;
      _location.text = widget.client!.location;
      _contract.text = widget.client!.contractValue.toString();
      _notes.text = widget.client!.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Client Name *'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number *',
            helperText: '10-digit mobile number',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _location,
          decoration: const InputDecoration(labelText: 'Project Location'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contract,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Contract Value'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name and phone are required')),
              );
              return;
            }
            await context.read<AppProvider>().saveClient(
              Client(
                id: widget.client?.id,
                name: _name.text.trim(),
                phone: _phone.text.trim(),
                location: _location.text.trim(),
                contractValue: double.tryParse(_contract.text) ?? 0,
                notes: _notes.text.trim(),
              ),
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save Client'),
        ),
      ],
    );
  }
}