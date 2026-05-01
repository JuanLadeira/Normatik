import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../../core/api/client.dart';
import 'auth_provider.dart';

class AcceptInvitePage extends ConsumerStatefulWidget {
  final String token;

  const AcceptInvitePage({super.key, required this.token});

  @override
  ConsumerState<AcceptInvitePage> createState() => _AcceptInvitePageState();
}

class _AcceptInvitePageState extends ConsumerState<AcceptInvitePage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleSetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final dio = ref.read(apiClientProvider).dio;
        await dio.post('/api/auth/accept-invite', data: {
          'invite_token': widget.token,
          'password': _passwordController.text,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Senha definida com sucesso! Agora você pode entrar.")),
          );
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Erro ao ativar conta. O link pode ter expirado."),
              backgroundColor: NormatiqColors.danger700,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NormatiqSpacing.s6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(NormatiqSpacing.s8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const NormatiqLogo(size: 32),
                      const SizedBox(height: 32),
                      const Text(
                        "Ative sua conta",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Defina sua senha inicial para acessar o laboratório.",
                        style: TextStyle(color: NormatiqColors.neutral500),
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: "Nova Senha",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (v) => v!.length < 6 ? "A senha deve ter pelo menos 6 caracteres" : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmController,
                              decoration: const InputDecoration(
                                labelText: "Confirmar Senha",
                                prefixIcon: Icon(Icons.lock_reset_outlined),
                              ),
                              obscureText: _obscurePassword,
                              validator: (v) => v != _passwordController.text ? "As senhas não conferem" : null,
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleSetPassword,
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text("Ativar Conta e Entrar"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
