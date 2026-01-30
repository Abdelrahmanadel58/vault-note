import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/models/entry.dart';
import '../../../core/services/vault_service.dart';

/// Provider للـ Box المشفر نفسه
final vaultBoxProvider = FutureProvider<Box<VaultEntry>>((ref) async {
  return await VaultService.openVaultBox();
});

/// Provider لقائمة الإدخالات (يُعاد حسابه تلقائيًا عند تغيير الـ box)
final entriesProvider = Provider<List<VaultEntry>>((ref) {
  final boxAsync = ref.watch(vaultBoxProvider);

  return boxAsync.when(
    data: (box) {
      return box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// اختياري: provider لعدد الإدخالات (لعرض badge أو شيء مشابه)
final entryCountProvider = Provider<int>((ref) {
  return ref.watch(entriesProvider).length;
});

/// اختياري: فلتر حسب الفئة (إذا أردت إضافة tabs أو dropdown للفئات)
final filteredEntriesProvider = Provider.family<List<VaultEntry>, String?>(
  (ref, category) {
    final all = ref.watch(entriesProvider);
    if (category == null || category == 'All') return all;
    return all.where((e) => e.category == category).toList();
  },
);