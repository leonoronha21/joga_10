import 'package:flutter/material.dart';
import 'package:joga_10/model/Estabelecimento.dart';

class EstabelecimentosDetalhes extends StatelessWidget{
  Estabelecimento estabelecimento;
   EstabelecimentosDetalhes({Key?key, required this.estabelecimento}) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Container(
      child: Wrap(
        children: [
          Image.network(estabelecimento.foto, height: 250, width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
          
          ),
          Padding(
            padding: EdgeInsets.only(top: 24, left: 24),
            child: Text(
              estabelecimento.nome,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 24, left: 24),
            child: Text(
              estabelecimento.endereco,
             
            ),
          ),
          
        ],
      ),
    );
  }
}