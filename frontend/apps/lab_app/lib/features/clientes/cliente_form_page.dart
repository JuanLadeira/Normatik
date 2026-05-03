import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/form_card.dart';
import 'clientes_provider.dart';

class ClienteFormPage extends ConsumerStatefulWidget {
  final int? clienteId;
  const ClienteFormPage({super.key, this.clienteId});

  @override
  ConsumerState<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends ConsumerState<ClienteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _contatoCtrl = TextEditingController();
  bool _ativo = true;
  bool _isLoading = false;

  bool get _isEdit => widget.clienteId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
    }
  }

  void _prefill() {
    final clientes = ref.read(clientesProvider).valueOrNull ?? [];
    final c = clientes.where((c) => c.id == widget.clienteId).firstOrNull;
    if (c != null) {
      _nomeCtrl.text = c.nome;
      _cnpjCtrl.text = c.cnpj ?? '';
      _emailCtrl.text = c.email ?? '';
      _telefoneCtrl.text = c.telefone ?? '';
      _contatoCtrl.text = c.contato ?? '';
      setState(() => _ativo = c.ativo);
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cnpjCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _contatoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'nome': _nomeCtrl.text.trim(),
      if (_cnpjCtrl.text.trim().isNotEmpty)
        'cnpj': _cnpjCtrl.text.replaceAll(RegExp(r'[^\d]'), ''),
      if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (_telefoneCtrl.text.trim().isNotEmpty)
        'telefone': _telefoneCtrl.text.trim(),
      if (_contatoCtrl.text.trim().isNotEmpty)
        'contato': _contatoCtrl.text.trim(),
      'ativo': _ativo,
    };

    try {
      final notifier = ref.read(clientesProvider.notifier);
      if (_isEdit) {
        await notifier.updateCliente(widget.clienteId!, data);
      } else {
        await notifier.createCliente(data);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar cliente: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Editar Cliente' : 'Novo Cliente',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(NormatiqSpacing.s4),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: FormCard(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nomeCtrl,
                    decoration: const InputDecoration(labelText: 'Nome *'),
                    enabled: !_isLoading,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: NormatiqSpacing.s4),
                  TextFormField(
                    controller: _cnpjCtrl,
                    decoration: const InputDecoration(
                        labelText: 'CNPJ',
                        hintText: '00.000.000/0001-00'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CnpjInputFormatter()],
                    validator: cnpjValidator,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: NormatiqSpacing.s4),
                  TextFormField(
                    controller: _contatoCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Contato'),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: NormatiqSpacing.s4),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration:
                        const InputDecoration(labelText: 'E-mail'),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: NormatiqSpacing.s4),
                  TextFormField(
                    controller: _telefoneCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Telefone'),
                    keyboardType: TextInputType.phone,
                    enabled: !_isLoading,
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: NormatiqSpacing.s4),
                    SwitchListTile(
                      title: const Text('Cliente ativo'),
                      value: _ativo,
                      onChanged: _isLoading
                          ? null
                          : (v) => setState(() => _ativo = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  const SizedBox(height: NormatiqSpacing.s6),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit
                            ? 'Salvar alterações'
                            : 'Criar cliente'),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
