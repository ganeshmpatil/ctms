import 'package:flutter/material.dart';

import '../api/client.dart';
import '../theme/theme_controller.dart';
import '../widgets/glass.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  final ApiClient api;
  final ThemeController theme;
  const LoginScreen({super.key, required this.api, required this.theme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'VijayPatil');
  final _password = TextEditingController(text: 'Welcome1');
  bool _busy = false;
  bool _obscure = true;
  String? _err;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await widget.api.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => HomeShell(api: widget.api, theme: widget.theme)),
      );
    } on ApiException catch (e) {
      setState(() => _err = e.message);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // Hero gradient backdrop
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.accent,
                ],
              ),
            ),
          ),
          // Decorative blurred circles
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(
                size: 240, color: AppColors.accentC.withValues(alpha: 0.35)),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _Blob(
                size: 280, color: AppColors.accentD.withValues(alpha: 0.28)),
          ),
          // Foreground content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand mark — white logo plate above the card
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: Column(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ShaderMask(
                              shaderCallback: (rect) => LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.accent,
                                ],
                              ).createShader(rect),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 38,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Gravity',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Class & Teacher Management',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Login card
                    Padding(
                      padding: const EdgeInsets.only(top: 32, bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        padding:
                            const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Welcome back',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Sign in to continue',
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.text,
                                autocorrect: false,
                                style:
                                    const TextStyle(color: AppColors.text),
                                decoration: glassInputDecoration(
                                  label: 'Username or email',
                                  icon: Icons.person_outline_rounded,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                style:
                                    const TextStyle(color: AppColors.text),
                                decoration: glassInputDecoration(
                                  label: 'Password',
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
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              if (_err != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                          Icons.error_outline_rounded,
                                          size: 18,
                                          color: AppColors.danger),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(_err!,
                                            style: const TextStyle(
                                                color: AppColors.danger,
                                                fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              GradientButton(
                                label: 'Sign In',
                                onPressed: _busy ? null : _submit,
                                busy: _busy,
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Contact your administrator to reset.'),
                                    ));
                                  },
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Footer
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Gravity · CTMS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
