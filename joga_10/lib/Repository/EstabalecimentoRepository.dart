import 'package:flutter/material.dart';
import '../model/Estabelecimento.dart';

class EstabelecimentoRepository extends ChangeNotifier{

  final List<Estabelecimento> _estabelecimento = [
   
    Estabelecimento(nome: 'R5 Sports', 
    endereco: 'Av.Farroupilha,2710', 
    foto: 'https://lh5.googleusercontent.com/p/AF1QipNtNYmjM3ILLvH-Ajx7MNY_duvUqKr9Enf6nK3p=w533-h240-k-no', 
    latitude: -29.921987728491363,  
    longitude: -51.16674141035525,),   
  ];

   List<Estabelecimento> get estabelecimentos => _estabelecimento;
}