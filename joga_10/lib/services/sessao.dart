import 'package:shared_preferences/shared_preferences.dart';

import 'package:joga_10/model/Usuario.dart';

/// Sessão do usuário logado.
///
/// Como não há servidor/JWT, a sessão é só o registro local de quem entrou.
class Sessao {
  Sessao._();
  static final Sessao instance = Sessao._();

  static const _kId = 'usuario_id';
  static const _kEmail = 'usuario_email';
  static const _kNome = 'usuario_nome';
  static const _kRole = 'usuario_role';

  Usuario? _atual;
  Usuario? get atual => _atual;

  Future<void> salvar(Usuario usuario) async {
    _atual = usuario;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kId, usuario.id);
    await prefs.setString(_kEmail, usuario.email);
    await prefs.setString(_kNome, usuario.nomeCompleto);
    await prefs.setString(_kRole, usuario.role);
  }

  Future<bool> estaLogado() async {
    if (_atual != null) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kId) != null;
  }

  Future<int?> get usuarioId async {
    if (_atual != null) return _atual!.id;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kId);
  }

  Future<void> sair() async {
    _atual = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kId);
    await prefs.remove(_kEmail);
    await prefs.remove(_kNome);
    await prefs.remove(_kRole);
  }
}
