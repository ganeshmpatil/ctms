import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/client.dart';
import '../../api/models.dart';
import '../../widgets/glass.dart';

class AdminLeadsScreen extends StatefulWidget {
  final ApiClient api;
  const AdminLeadsScreen({super.key, required this.api});

  @override
  State<AdminLeadsScreen> createState() => _AdminLeadsScreenState();
}

class _AdminLeadsScreenState extends State<AdminLeadsScreen> {
  List<Lead> _items = [];
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
      final list = await widget.api.leads();
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
      builder: (_) => _LeadCreator(api: widget.api),
    );
    if (saved == true) await _load();
  }

  Future<void> _toggleResolved(Lead l) async {
    try {
      await widget.api.updateLead(
        id: l.id,
        isResolved: !l.isResolved,
        status: !l.isResolved ? 'resolved' : 'open',
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
      appBar: AppBar(title: const Text('Leads')),
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
                  child: _items.isEmpty
                      ? const Center(
                          child: Text('No leads yet',
                              style: TextStyle(color: AppColors.muted)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final l = _items[i];
                            return GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(l.query,
                                            style: const TextStyle(
                                                color: AppColors.text,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                      ),
                                      _StatusPill(
                                          resolved: l.isResolved,
                                          status: l.status),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (l.raisedBy != null ||
                                      l.contactNumber != null)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        [
                                          if (l.raisedBy != null) l.raisedBy!,
                                          if (l.contactNumber != null)
                                            l.contactNumber!
                                        ].join(' · '),
                                        style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12),
                                      ),
                                    ),
                                  if (l.comments != null &&
                                      l.comments!.isNotEmpty)
                                    Text(l.comments!,
                                        style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat('dd MMM yyyy')
                                            .format(l.createdAt),
                                        style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 11),
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () => _toggleResolved(l),
                                        icon: Icon(
                                          l.isResolved
                                              ? Icons.replay_rounded
                                              : Icons.check_circle_outline_rounded,
                                          size: 16,
                                          color: l.isResolved
                                              ? AppColors.muted
                                              : AppColors.success,
                                        ),
                                        label: Text(
                                          l.isResolved
                                              ? 'Reopen'
                                              : 'Mark resolved',
                                          style: TextStyle(
                                            color: l.isResolved
                                                ? AppColors.muted
                                                : AppColors.success,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
        label: const Text('New lead'),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool resolved;
  final String status;
  const _StatusPill({required this.resolved, required this.status});

  @override
  Widget build(BuildContext context) {
    final fg = resolved ? AppColors.success : AppColors.warning;
    final bg = resolved ? AppColors.successLight : AppColors.warningLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        resolved ? 'RESOLVED' : status.toUpperCase(),
        style: TextStyle(
            color: fg,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5),
      ),
    );
  }
}

class _LeadCreator extends StatefulWidget {
  final ApiClient api;
  const _LeadCreator({required this.api});

  @override
  State<_LeadCreator> createState() => _LeadCreatorState();
}

class _LeadCreatorState extends State<_LeadCreator> {
  final _formKey = GlobalKey<FormState>();
  final _query = TextEditingController();
  final _raisedBy = TextEditingController();
  final _contact = TextEditingController();
  final _comments = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _query.dispose();
    _raisedBy.dispose();
    _contact.dispose();
    _comments.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.api.createLead(
        query: _query.text.trim(),
        raisedBy:
            _raisedBy.text.trim().isEmpty ? null : _raisedBy.text.trim(),
        contactNumber:
            _contact.text.trim().isEmpty ? null : _contact.text.trim(),
        comments:
            _comments.text.trim().isEmpty ? null : _comments.text.trim(),
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
          child: SingleChildScrollView(
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
                const Text('New lead',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _query,
                  decoration: glassInputDecoration(label: 'Inquiry'),
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _raisedBy,
                  decoration: glassInputDecoration(label: 'Raised by'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contact,
                  keyboardType: TextInputType.phone,
                  decoration: glassInputDecoration(label: 'Contact number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _comments,
                  decoration: glassInputDecoration(label: 'Comments'),
                  maxLines: 3,
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
      ),
    );
  }
}
