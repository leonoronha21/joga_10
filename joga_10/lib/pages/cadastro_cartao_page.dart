import 'package:flutter/material.dart';

import 'package:joga_10/repositories/cartao_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_colors.dart';

class CadastroCartaoPage extends StatefulWidget {
  const CadastroCartaoPage({super.key});

  @override
  State<CadastroCartaoPage> createState() => _CadastroCartaoPageState();
}

class _CadastroCartaoPageState extends State<CadastroCartaoPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = CartaoRepository();

  final _titular = TextEditingController();
  final _numero = TextEditingController();
  final _validade = TextEditingController();
  String _bandeira = 'Visa';
  bool _salvando = false;

  @override
  void dispose() {
    _titular.dispose();
    _numero.dispose();
    _validade.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final id = Sessao.instance.atual?.id;
    if (id == null) return;
    setState(() => _salvando = true);
    try {
      await _repo.salvar(
        idUser: id,
        nomeTitular: _titular.text,
        bandeira: _bandeira,
        numeroCompleto: _numero.text,
        validade: _validade.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar o cartão.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo cartão')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.info, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Por segurança, guardamos apenas os últimos 4 dígitos. '
                      'O número completo e o CVC não são armazenados.',
                      style: TextStyle(fontSize: 12, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titular,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do titular',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o titular' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _numero,
              keyboardType: TextInputType.number,
              maxLength: 19,
              decoration: const InputDecoration(
                labelText: 'Número do cartão',
                prefixIcon: Icon(Icons.credit_card),
                counterText: '',
              ),
              validator: (v) {
                final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return d.length < 4 ? 'Número inválido' : null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _validade,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Validade (MM/AAAA)',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _bandeira,
                    decoration: const InputDecoration(labelText: 'Bandeira'),
                    items: const ['Visa', 'Mastercard', 'Elo', 'Amex', 'Outro']
                        .map((b) =>
                            DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (b) => setState(() => _bandeira = b ?? 'Visa'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Text('SALVAR CARTÃO'),
            ),
          ],
        ),
      ),
    );
  }
}
