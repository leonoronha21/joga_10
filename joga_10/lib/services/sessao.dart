import 'package:shared_preferences/shared_preferences.dart';

import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/model/Usuario.dart';

/// Sessão do usuário logado.
///
/// Como não há servidor/JWT, a sessão é só o registro local de quem entrou.
class Sessao implements SessaoContract {
  Sessao._();
  static final Sessao instance = Sessao._();
  factory Sessao() => instance;

  static const _kId = 'usuario_id';
  static const _kEmail = 'usuario_email';
  static const _kNome = 'usuario_nome';
  static const _kRole = 'usuario_role';

  Usuario? _atual;
  @override
  Usuario? get atual => _atual;

  bool get isAdminLocal => _atual?.id == 0;

  @override
  Future<void> salvar(Usuario usuario) async {
    _atual = usuario;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kId, usuario.id);
    await prefs.setString(_kEmail, usuario.email);
    await prefs.setString(_kNome, usuario.nomeCompleto);
    await prefs.setString(_kRole, usuario.role);
  }

  @override
  Future<bool> estaLogado() async {
    if (_atual != null) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kId) != null;
  }

  @override
  Future<Usuario?> restaurarLocal() async {
    if (_atual != null) return _atual;

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_kId);
    final email = prefs.getString(_kEmail);
    final nome = prefs.getString(_kNome);
    if (id == null || email == null) return null;

    final partes = (nome ?? '').trim().split(RegExp(r'\s+'));
    final primeiroNome =
        partes.isNotEmpty && partes.first.isNotEmpty ? partes.first : email;
    final segundoNome = partes.length > 1 ? partes.skip(1).join(' ') : null;

    _atual = Usuario(
      id: id,
      primeiroNome: primeiroNome,
      segundoNome:
          segundoNome != null && segundoNome.isNotEmpty ? segundoNome : null,
      email: email,
      role: prefs.getString(_kRole) ?? 'USER',
    );
    return _atual;
  }

  @override
  Future<int?> get usuarioId async {
    if (_atual != null) return _atual!.id;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kId);
  }

  @override
  Future<void> sair() async {
    _atual = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kId);
    await prefs.remove(_kEmail);
    await prefs.remove(_kNome);
    await prefs.remove(_kRole);
  }
}
