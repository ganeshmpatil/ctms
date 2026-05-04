import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/models.dart';
import '../../widgets/glass.dart';

class AdminUsersScreen extends StatefulWidget {
  final ApiClient api;
  const AdminUsersScreen({super.key, required this.api});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AuthUser> _items = [];
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
      final list = await widget.api.listAuthUsers();
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

  Future<void> _resetPassword(AuthUser u) async {
    final newPw = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResetPasswordSheet(email: u.email),
    );
    if (newPw == null || newPw.isEmpty) return;
    try {
      await widget.api.adminResetPassword(userId: u.id, newPassword: newPw);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset for ${u.email}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(title: const Text('Users')),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _err != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_err!,
                        style: const TextStyle(color: AppColors.text)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final u = _items[i];
                      return GlassCard(
                        padding: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              u.email.isNotEmpty
                                  ? u.email[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(u.email,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            u.role.toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w700),
                          ),
                          trailing: IconButton(
                            tooltip: 'Reset password',
                            icon: const Icon(Icons.lock_reset_rounded,
                                color: AppColors.muted),
                            onPressed: () => _resetPassword(u),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ResetPasswordSheet extends StatefulWidget {
  final String email;
  const _ResetPasswordSheet({required this.email});

  @override
  State<_ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<_ResetPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _next = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, inset),
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
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Reset password',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text('for ${widget.email}',
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _next,
                obscureText: _obscure,
                style: const TextStyle(color: AppColors.text),
                decoration: glassInputDecoration(
                  label: 'New password',
                  icon: Icons.lock_outline_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Reset',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).pop(_next.text);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
