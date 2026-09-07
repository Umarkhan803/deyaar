import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_actions.dart';
import 'client_view_screen.dart';

class ClientsScreen extends StatefulWidget {
  final bool openAdd;
  const ClientsScreen({super.key, this.openAdd = false});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_opened && widget.openAdd) {
        _opened = true;
        _openForm(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final currency = app.settings.currency;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: app.clients.isEmpty
          ? const EmptyState(
              message: 'No clients yet. Tap + to add a client.',
              icon: Icons.people_outline,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: app.clients.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = app.clients[i];
                return Card(
                  child: ListTile(
                    title: Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        if (c.phone.isNotEmpty) c.phone,
                        if (c.location.isNotEmpty) c.location,
                        Formatters.money(c.contractValue, currency: currency),
                      ].join(' · '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit Client',
                          onPressed: () => _openForm(context, client: c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outlined),
                          tooltip: 'Delete Client',
                          onPressed: () => _deleteClient(context, c),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClientViewScreen(clientId: c.id!))),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openForm(BuildContext context, {Client? client}) async {
    final name = TextEditingController(text: client?.name ?? '');
    final phone = TextEditingController(text: client?.phone ?? '');
    final location = TextEditingController(text: client?.location ?? '');
    final contract = TextEditingController(
      text: client == null ? '' : client.contractValue.toString(),
    );
    final notes = TextEditingController(text: client?.notes ?? '');

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text(client == null ? 'Add Client' : 'Edit Client'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Client Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  helperText: '10-digit mobile number',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: location,
                decoration: const InputDecoration(
                  labelText: 'Project Location',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contract,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Contract Value'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 24),
              FormActions(
                primaryLabel: 'Save Client',
                onCancel: () => Navigator.pop(ctx),
                onPrimary: () async {
                  if (name.text.trim().isEmpty || phone.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Name and phone are required'),
                      ),
                    );
                    return;
                  }
                  await context.read<AppProvider>().saveClient(
                    Client(
                      id: client?.id,
                      name: name.text.trim(),
                      phone: phone.text.trim(),
                      location: location.text.trim(),
                      contractValue: double.tryParse(contract.text) ?? 0,
                      notes: notes.text.trim(),
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteClient(BuildContext context, Client client) async {
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
      await context.read<AppProvider>().removeClient(client.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client deleted successfully')),
        );
      }
    }
  }
}