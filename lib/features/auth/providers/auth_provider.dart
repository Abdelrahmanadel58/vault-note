import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/vault_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool hasPinSetup;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.hasPinSetup = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? hasPinSetup,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      hasPinSetup: hasPinSetup ?? this.hasPinSetup,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  Timer? _autoLockTimer;

  AuthNotifier(this.ref) : super(AuthState()) {
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final has = await VaultService.hasSetup();
    state = state.copyWith(hasPinSetup: has, isLoading: false);
  }

  Future<bool> setupPin(String pin) async {
    state = state.copyWith(isLoading: true);
    try {
      await VaultService.setupPin(pin);
      state = state.copyWith(hasPinSetup: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> unlockWithPin(String pin) async {
    state = state.copyWith(isLoading: true);
    final success = await VaultService.verifyPin(pin);
    if (success) {
      // فتح الصندوق المشفر
      await VaultService.openVaultBox();
      state = state.copyWith(isAuthenticated: true, isLoading: false);
      _resetAutoLock();
    } else {
      state = state.copyWith(isLoading: false);
    }
    return success;
  }

  Future<bool> unlockWithBiometric() async {
    state = state.copyWith(isLoading: true);
    final success = await VaultService.authenticateBiometric();
    if (success) {
      await VaultService.openVaultBox();
      state = state.copyWith(isAuthenticated: true, isLoading: false);
      _resetAutoLock();
    } else {
      state = state.copyWith(isLoading: false);
    }
    return success;
  }

  void lock() {
    _autoLockTimer?.cancel();
    state = state.copyWith(isAuthenticated: false);
  }

  void _resetAutoLock() {
    _autoLockTimer?.cancel();
    _autoLockTimer = Timer(const Duration(minutes: 3), () {
      lock();
    });
  }

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    super.dispose();
  }
}