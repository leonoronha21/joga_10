import 'package:flutter/material.dart';

import 'package:joga_10/pages/partida_detalhe_page.dart';

class PartidaLinkRedirect extends StatefulWidget {
  final int partidaId;
  final Widget child;

  const PartidaLinkRedirect({
    super.key,
    required this.partidaId,
    required this.child,
  });

  @override
  State<PartidaLinkRedirect> createState() => _PartidaLinkRedirectState();
}

class _PartidaLinkRedirectState extends State<PartidaLinkRedirect> {
  bool _abriu = false;

  @override
  void initState() {
    super.initState();
    _abrirDepoisDoBuild();
  }

  @override
  void didUpdateWidget(covariant PartidaLinkRedirect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partidaId != widget.partidaId) {
      _abriu = false;
      _abrirDepoisDoBuild();
    }
  }

  void _abrirDepoisDoBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _abriu) return;
      _abriu = true;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PartidaDetalhePage(partidaId: widget.partidaId),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
