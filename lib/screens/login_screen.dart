import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pin = TextEditingController();
  final _auth = LocalAuthentication();
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    final app = context.read<AppProvider>();
    if (!app.settings.biometricEnabled) return;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Deyaar Constructions',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (ok && mounted) app.unlockBiometric();
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await context.read<AppProvider>().unlock(_pin.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) setState(() => _error = 'Incorrect PIN');
  }

  @override
  Widget build(BuildContext context) {
    final biometric = context.watch<AppProvider>().settings.biometricEnabled;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Image.asset(
                  'assets/brand/logo_full.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.apartment,
                    size: 72,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                style: const TextStyle(
                  letterSpacing: 8,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Enter PIN',
                  counterText: '',
                  hintText: '••••',
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Unlock'),
                ),
              ),
              if (biometric) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use fingerprint'),
                ),
              ],
              const Spacer(flex: 3),
              Text(
                'All data stays on this device. No internet required.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
