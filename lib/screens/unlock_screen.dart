import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_provider.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Color(0xFF0A84FF)),
              const SizedBox(height: 40),
              const Text('أدخل رمز PIN', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, letterSpacing: 16),
                maxLength: 6,
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final success = await ref
                            .read(authProvider.notifier)
                            .unlockWithPin(_pinController.text);
                        if (success && context.mounted) {
                          Navigator.pushReplacementNamed(context, '/vault');
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('رمز PIN غير صحيح')),
                          );
                        }
                      },
                child: const Text('فتح الخزنة'),
              ),
              const SizedBox(height: 24),
              FutureBuilder<bool>(
                future: VaultService.canUseBiometrics(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == true) {
                    return OutlinedButton.icon(
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('استخدام البصمة / الوجه'),
                      onPressed: () async {
                        final success = await ref
                            .read(authProvider.notifier)
                            .unlockWithBiometric();
                        if (success && context.mounted) {
                          Navigator.pushReplacementNamed(context, '/vault');
                        }
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}