import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isLoading) {
        if (next.hasPinSetup) {
          Navigator.pushReplacementNamed(context, '/unlock');
        } else {
          Navigator.pushReplacementNamed(context, '/setup-pin');
        }
      }
    });

    // نتحقق مرة واحدة عند التحميل
    Future.microtask(() {
      ref.read(authProvider.notifier)._checkSetup();
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 100, color: Color(0xFF0A84FF)),
            SizedBox(height: 32),
            Text(
              'VaultNote',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}