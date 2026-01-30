class AddEditEntryScreen extends ConsumerStatefulWidget {
  final VaultEntry? existingEntry;

  const AddEditEntryScreen({super.key, this.existingEntry});

  @override
  ConsumerState<AddEditEntryScreen> createState() => _AddEditEntryScreenState();
}

class _AddEditEntryScreenState extends ConsumerState<AddEditEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _noteCtrl;

  String _selectedCategory = 'Other';

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existingEntry?.title ?? '');
    _usernameCtrl = TextEditingController(text: widget.existingEntry?.usernameOrEmail ?? '');
    _passwordCtrl = TextEditingController(text: widget.existingEntry?.password ?? '');
    _noteCtrl = TextEditingController(text: widget.existingEntry?.note ?? '');
    _selectedCategory = widget.existingEntry?.category ?? 'Other';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final newPass = PasswordGenerator.generate(length: 20, symbols: true);
    setState(() {
      _passwordCtrl.text = newPass;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final box = await ref.read(vaultBoxProvider.future);

    final entry = VaultEntry(
      id: widget.existingEntry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      usernameOrEmail: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
      password: _passwordCtrl.text.trim().isEmpty ? null : _passwordCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      category: _selectedCategory,
      createdAt: widget.existingEntry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await box.put(entry.id, entry);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEntry == null ? 'Add Entry' : 'Edit Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username / Email'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _generatePassword,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Generate'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Personal', 'Work', 'Banking', 'Other']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Secure Note',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                child: const Text('Save Entry', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}