import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/models.dart';
import '../../widgets/glass.dart';

class AdminSubjectsScreen extends StatefulWidget {
  final ApiClient api;
  const AdminSubjectsScreen({super.key, required this.api});

  @override
  State<AdminSubjectsScreen> createState() => _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends State<AdminSubjectsScreen> {
  List<Subject> _items = [];
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
      final list = await widget.api.subjects();
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

  Future<void> _openCreate() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubjectCreator(api: widget.api),
    );
    if (saved == true) await _load();
  }

  Future<void> _confirmDelete(Subject s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete subject?'),
        content: Text('${s.description} will be removed.'),
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
      await widget.api.deleteSubject(s.id);
      if (!mounted) return;
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
      appBar: AppBar(title: const Text('Subjects')),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _err != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_err!,
                        style: const TextStyle(color: AppColors.text))),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final s = _items[i];
                      return GlassCard(
                        padding: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.menu_book_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          title: Text(s.description,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.muted, size: 20),
                            onPressed: () => _confirmDelete(s),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New subject'),
      ),
    );
  }
}

class _SubjectCreator extends StatefulWidget {
  final ApiClient api;
  const _SubjectCreator({required this.api});

  @override
  State<_SubjectCreator> createState() => _SubjectCreatorState();
}

class _SubjectCreatorState extends State<_SubjectCreator> {
  final _formKey = GlobalKey<FormState>();
  final _desc = TextEditingController();
  bool _isEnglish = false;
  bool _isHindi = false;
  bool _busy = false;

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.api.createSubject(
        description: _desc.text.trim(),
        isEnglish: _isEnglish,
        isHindi: _isHindi,
      );
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
              const Text('New subject',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _desc,
                decoration: glassInputDecoration(label: 'Description'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                title: const Text('Taught in English'),
                value: _isEnglish,
                onChanged: (v) => setState(() => _isEnglish = v),
              ),
              SwitchListTile.adaptive(
                title: const Text('Taught in Hindi'),
                value: _isHindi,
                onChanged: (v) => setState(() => _isHindi = v),
              ),
              const SizedBox(height: 16),
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
