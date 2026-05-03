import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/models.dart';
import '../../widgets/glass.dart';

class AdminDivisionsScreen extends StatefulWidget {
  final ApiClient api;
  const AdminDivisionsScreen({super.key, required this.api});

  @override
  State<AdminDivisionsScreen> createState() => _AdminDivisionsScreenState();
}

class _AdminDivisionsScreenState extends State<AdminDivisionsScreen> {
  List<Division> _items = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final list = await widget.api.divisions();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openEditor({Division? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DivisionEditor(api: widget.api, existing: existing),
    );
    if (saved == true) await _load();
  }

  Future<void> _confirmDelete(Division d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete division?'),
        content: Text(
            '${d.label} will be removed. This is blocked if any students are still assigned.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.deleteDivision(d.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${d.label} deleted')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg1,
      appBar: AppBar(title: const Text('Divisions')),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _err != null
              ? _ErrorBox(message: _err!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final d = _items[i];
                      return GlassCard(
                        padding: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: d.medium == 'english'
                                  ? AppColors.primaryLight
                                  : AppColors.warningLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${d.standard}',
                              style: TextStyle(
                                color: d.medium == 'english'
                                    ? AppColors.primary
                                    : AppColors.warning,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(d.label,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            d.medium[0].toUpperCase() + d.medium.substring(1),
                            style:
                                const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded,
                                    color: AppColors.muted, size: 20),
                                onPressed: () => _openEditor(existing: d),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.muted, size: 20),
                                onPressed: () => _confirmDelete(d),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New division'),
      ),
    );
  }
}

class _DivisionEditor extends StatefulWidget {
  final ApiClient api;
  final Division? existing;
  const _DivisionEditor({required this.api, this.existing});

  @override
  State<_DivisionEditor> createState() => _DivisionEditorState();
}

class _DivisionEditorState extends State<_DivisionEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _standard;
  late String _medium;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _standard = TextEditingController(
        text: widget.existing?.standard.toString() ?? '');
    _medium = widget.existing?.medium ?? 'english';
  }

  @override
  void dispose() {
    _standard.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final std = int.tryParse(_standard.text.trim());
    if (std == null) return;
    setState(() => _busy = true);
    try {
      if (widget.existing == null) {
        await widget.api.createDivision(standard: std, medium: _medium);
      } else {
        await widget.api.updateDivision(
            id: widget.existing!.id, standard: std, medium: _medium);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + inset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(widget.existing == null ? 'New division' : 'Edit division',
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _standard,
                keyboardType: TextInputType.number,
                decoration:
                    glassInputDecoration(label: 'Standard (1–12)'),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return (n == null || n < 1 || n > 12) ? '1..12' : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _medium,
                decoration: glassInputDecoration(label: 'Medium'),
                items: const [
                  DropdownMenuItem(value: 'english', child: Text('English')),
                  DropdownMenuItem(value: 'marathi', child: Text('Marathi')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _medium = v);
                },
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Save',
                onPressed: _busy ? null : _save,
                busy: _busy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 36, color: AppColors.muted),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.text)),
              const SizedBox(height: 12),
              GradientButton(label: 'Retry', onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
