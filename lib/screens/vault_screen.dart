import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xfile/xfile.dart'; // من share_plus

import '../../core/models/entry.dart';
import '../../core/services/vault_service.dart';
import '../../features/vault/providers/vault_provider.dart'; // entriesProvider
import '../add_edit_entry_screen.dart';
import '../settings_screen.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VaultNote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'تصدير النسخة الاحتياطية',
            onPressed: () => _handleExport(context, ref),
          ),
        ],
      ),

      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 24),
                  Text(
                    'لا توجد بيانات بعد',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text('اضغط + لإضافة كلمة مرور أو ملاحظة آمنة'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    entry.category[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(entry.title),
                subtitle: Text(
                  entry.usernameOrEmail ?? 'لا يوجد اسم مستخدم',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditEntryScreen(existingEntry: entry),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('حدث خطأ: $err'),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditEntryScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // Export مع طلب كلمة مرور
  // ────────────────────────────────────────────────
  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    final password = await _showExportPasswordDialog(context);

    if (password == null || password.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كلمة المرور مطلوبة للتصدير')),
        );
      }
      return;
    }

    try {
      final file = await VaultService.exportVault(password.trim());

      if (file != null && context.mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              'نسخة احتياطية مشفرة من VaultNote\nكلمة المرور التي اخترتها مطلوبة للاستيراد لاحقاً',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تصدير النسخة الاحتياطية بنجاح'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التصدير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Export error: $e');
    }
  }

  // ────────────────────────────────────────────────
  // Dialog لطلب كلمة مرور التصدير
  // ────────────────────────────────────────────────
  Future<String?> _showExportPasswordDialog(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حماية النسخة الاحتياطية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'أدخل كلمة مرور لتشفير ملف النسخة الاحتياطية:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                  helperText:
                      'احفظها في مكان آمن، لن تتمكن من الاستيراد بدونها',
                  helperStyle: TextStyle(color: Colors.orangeAccent),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                final pass = controller.text.trim();
                if (pass.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('كلمة المرور قصيرة جدًا (4 أحرف على الأقل)')),
                  );
                  return;
                }
                Navigator.pop(context, pass);
              },
              child: const Text('تصدير'),
            ),
          ],
        );
      },
    );
  }
}