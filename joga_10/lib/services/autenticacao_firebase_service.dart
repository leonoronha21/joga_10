import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:joga_10/domain/contracts/autenticacao_firebase_contract.dart';
import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/services/local_demo_data.dart';

class AutenticacaoFirebaseService implements AutenticacaoFirebaseContract {
  final firebase_auth.FirebaseAuth? _authConfigurado;
  final FirebaseFirestore? _firestoreConfigurado;
  final GoogleSignIn? _googleSignInConfigurado;

  AutenticacaoFirebaseService({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _authConfigurado = auth,
        _firestoreConfigurado = firestore,
        _googleSignInConfigurado = googleSignIn;

  firebase_auth.FirebaseAuth get _auth =>
      _authConfigurado ?? firebase_auth.FirebaseAuth.instance;

  FirebaseFirestore get _firestore =>
      _firestoreConfigurado ?? FirebaseFirestore.instance;

  GoogleSignIn get _googleSignIn => _googleSignInConfigurado ?? GoogleSignIn();

  @override
  bool get autenticado => _auth.currentUser != null;

  @override
  Future<Usuario?> entrarComGoogle() async {
    final firebase_auth.UserCredential credencial;
    if (kIsWeb) {
      credencial = await _auth.signInWithPopup(
        firebase_auth.GoogleAuthProvider(),
      );
    } else {
      final contaGoogle = await _googleSignIn.signIn();
      if (contaGoogle == null) return null;

      final autenticacaoGoogle = await contaGoogle.authentication;
      final credencialGoogle = firebase_auth.GoogleAuthProvider.credential(
        accessToken: autenticacaoGoogle.accessToken,
        idToken: autenticacaoGoogle.idToken,
      );
      credencial = await _auth.signInWithCredential(credencialGoogle);
    }

    final usuarioFirebase = credencial.user;
    if (usuarioFirebase == null) return null;

    final usuario = _usuarioDemo(usuarioFirebase);
    try {
      await _salvarPerfilFirestore(usuarioFirebase, usuario);
    } on FirebaseException catch (erro) {
      // A autenticação já foi concluída. Uma indisponibilidade momentânea ou
      // regra desatualizada do Firestore não deve impedir a entrada no app.
      debugPrint(
        'Login Google concluído; perfil Firestore não sincronizado: '
        '${erro.code} ${erro.message}',
      );
    }
    return usuario;
  }

  Future<void> _salvarPerfilFirestore(
    firebase_auth.User usuarioFirebase,
    Usuario usuario,
  ) async {
    final referencia =
        _firestore.collection('usuarios').doc(usuarioFirebase.uid);
    final existente = await referencia.get();
    final batch = _firestore.batch();
    batch.set(
      referencia,
      {
        'firebaseUid': usuarioFirebase.uid,
        'primeiroNome': usuario.primeiroNome,
        'segundoNome': usuario.segundoNome,
        'nomeCompleto': usuario.nomeCompleto,
        'email': usuario.email,
        'fotoUrlGoogle': usuarioFirebase.photoURL,
        'role': usuario.role,
        'provedor': 'GOOGLE',
        'ambiente': 'DEMO',
        'ativo': true,
        'atualizadoEm': FieldValue.serverTimestamp(),
        if (!existente.exists) 'criadoEm': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _firestore.collection('usuariosPublicos').doc(usuarioFirebase.uid),
      {
        'primeiroNome': usuario.primeiroNome,
        'segundoNome': usuario.segundoNome,
        'nomeCompleto': usuario.nomeCompleto,
        'fotoUrl': usuarioFirebase.photoURL,
        'cidade': usuario.cidade,
        'ativo': true,
        'atualizadoEm': FieldValue.serverTimestamp(),
        if (!existente.exists) 'criadoEm': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Usuario _usuarioDemo(firebase_auth.User usuarioFirebase) {
    final nome = (usuarioFirebase.displayName ?? '').trim();
    final partes = nome.isEmpty ? <String>[] : nome.split(RegExp(r'\s+'));
    final email = usuarioFirebase.email ?? '';
    return Usuario(
      // Compatibilidade temporaria: os fluxos demo ainda usam IDs numericos.
      id: LocalDemoData.adminId,
      primeiroNome: partes.isEmpty ? email.split('@').first : partes.first,
      segundoNome: partes.length > 1 ? partes.skip(1).join(' ') : null,
      email: email,
      role: 'USER',
    );
  }

  @override
  Future<void> sair() async {
    await _auth.signOut();
    if (!kIsWeb) await _googleSignIn.signOut();
  }
}
