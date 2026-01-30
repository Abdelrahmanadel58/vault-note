import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_provider.dart';

class SetupPinScreen extends ConsumerStatefulWidget {
  const SetupPinScreen({super.key});

  @override
  ConsumerState<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends ConsumerState<SetupPinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Color(0xFF34C759)),
              const SizedBox(height: 40),
              const Text('إنشاء رمز PIN', style: TextStyle(fontSize: 28)),
              const SizedBox(height: 48),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 36, letterSpacing: 12),
                decoration: InputDecoration(
                  hintText: 'رمز PIN (6 أرقام)',
                  errorText: _errorMessage,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 36, letterSpacing: 12),
                decoration: const InputDecoration(
                  hintText: 'تأكيد الرمز',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final pin = _pinController.text.trim();
                          final confirm = _confirmController.text.trim();

                          if (pin.length < 4) {
                            setState(() => _errorMessage = 'الرمز قصير جدًا');
                            return;
                          }
                          if (pin != confirm) {
                            setState(() => _errorMessage = 'الرمزان غير متطابقين');
                            return;
                          }

                          setState(() => _errorMessage = null);

                          final success = await ref.read(authProvider.notifier).setupPin(pin);
                          if (success && context.mounted) {
                            Navigator.pushReplacementNamed(context, '/unlock');
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Text('إنشاء الرمز', style: TextStyle(fontSize: 18)),
                ),
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
    _confirmController.dispose();
    super.dispose();
  }
}