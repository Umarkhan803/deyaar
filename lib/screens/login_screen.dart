import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
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
  bool _biometricBusy = false;
  bool _hardwareReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshBiometricSupport();
      if (!mounted) return;
      final enabled = context.read<AppProvider>().settings.biometricEnabled;
      if (enabled && _hardwareReady) {
        await _tryBiometric();
      }
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _refreshBiometricSupport() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      final enrolled = await _auth.getAvailableBiometrics();
      if (!mounted) return;
      setState(() {
        _hardwareReady = (canCheck || supported) && enrolled.isNotEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _hardwareReady = false);
    }
  }

  Future<void> _tryBiometric() async {
    final app = context.read<AppProvider>();
    if (!app.settings.biometricEnabled) return;
    if (_biometricBusy) return;

    setState(() {
      _biometricBusy = true;
      _error = null;
    });

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!canCheck && !supported) {
        if (mounted) {
          setState(() => _error = 'Fingerprint not available on this device');
        }
        return;
      }

      final enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) {
        if (mounted) {
          setState(
            () => _error =
                'No fingerprint enrolled. Add one in device settings.',
          );
        }
        return;
      }

      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Deyaar Constructions',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Fingerprint unlock',
            signInHint: 'Touch the fingerprint sensor',
            cancelButton: 'Use PIN',
          ),
          IOSAuthMessages(
            cancelButton: 'Use PIN',
            localizedFallbackTitle: 'Use PIN',
          ),
        ],
      );
      if (ok && mounted) {
        app.unlockBiometric();
      }
    } on LocalAuthException catch (e) {
      if (!mounted) return;
      // User cancel / fallback — stay on PIN screen quietly.
      if (e.code == LocalAuthExceptionCode.userCanceled ||
          e.code == LocalAuthExceptionCode.userRequestedFallback ||
          e.code == LocalAuthExceptionCode.systemCanceled) {
        return;
      }
      setState(() {
        _error = switch (e.code) {
          LocalAuthExceptionCode.noBiometricHardware ||
          LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
            'Fingerprint not available on this device',
          LocalAuthExceptionCode.noBiometricsEnrolled ||
          LocalAuthExceptionCode.noCredentialsSet =>
            'No fingerprint enrolled. Add one in device settings.',
          LocalAuthExceptionCode.temporaryLockout ||
          LocalAuthExceptionCode.biometricLockout =>
            'Too many attempts. Use your PIN.',
          LocalAuthExceptionCode.uiUnavailable =>
            'Fingerprint setup error. Please reinstall the app.',
          _ => e.description?.isNotEmpty == true
              ? e.description!
              : 'Fingerprint unlock failed. Use PIN.',
        };
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Fingerprint unlock failed. Use PIN.');
      }
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
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
    final showFingerprint = biometric;

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
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.danger),
                ),
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
              if (showFingerprint) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _biometricBusy ? null : _tryBiometric,
                  icon: _biometricBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fingerprint),
                  label: Text(
                    _biometricBusy ? 'Waiting for fingerprint…' : 'Use fingerprint',
                  ),
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
