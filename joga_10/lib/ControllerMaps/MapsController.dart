import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:joga_10/Repository/EstabalecimentoRepository.dart';
import 'package:joga_10/model/Estabelecimento.dart';
import 'package:joga_10/pages/estabelecimentosDetalhes.dart';
import 'package:joga_10/pages/login_page.dart';
import 'package:joga_10/pages/pagina2.dart';


class MapsController extends ChangeNotifier{

  double latitude=0;
  double longitude=0;
  String erro= '';
  Set<Marker> markers = Set<Marker>();
  late GoogleMapController _mapsController;
 

 // MapsController(){
   // getPosicao();
  //}
  get mapsController => _mapsController;
 
  onMapCreated(GoogleMapController gmc)async{
    _mapsController = gmc;
    getPosicao();
    loadEstabelecimentos();
  }

  loadEstabelecimentos(){
    final estabelecimentos = EstabelecimentoRepository().estabelecimentos;
    estabelecimentos.forEach((Estabelecimento) async{
        print('Latitude: ${Estabelecimento.latitude}, Longitude: ${Estabelecimento.longitude}');
      markers.add(Marker(
      
        markerId: MarkerId(Estabelecimento.nome),
        position: LatLng(Estabelecimento.latitude, Estabelecimento.longitude),
         icon: await BitmapDescriptor.fromAssetImage(
            ImageConfiguration(),
            'lib/assets/img/objetivo.png',
          ),
        onTap: () => {
           showModalBottomSheet(
                context: appKey.currentState!.context,
              builder: (context) => EstabelecimentosDetalhes(estabelecimento: Estabelecimento),
            )
          },
        ),
      );
    });
    
    notifyListeners();
  }
  getPosicao()async{
    try{
      Position posicao = await _posicaoAtual();
      latitude = posicao.latitude;
      longitude = posicao.longitude;
      _mapsController.animateCamera(CameraUpdate.newLatLng(LatLng(latitude, longitude)));
    }catch(e){
      erro = e.toString();
    }
  notifyListeners();
  }

  Future<Position> _posicaoAtual()async{

    LocationPermission permissao;

    bool ativado = await Geolocator.isLocationServiceEnabled();

    if(!ativado){
      return Future.error('Por favor habilite a localização no seu celular!');
    }    

    permissao = await Geolocator.checkPermission();

    if(permissao == LocationPermission.denied){
      permissao = await Geolocator.requestPermission();
       if(permissao == LocationPermission.denied){
        return Future.error("Você precisa autorizar o acesso a localização");
     }
       
    }

    if(permissao == LocationPermission.deniedForever){
      return Future.error("Você precisa liberar a localização para está funcionalidade");
    }

    return await Geolocator.getCurrentPosition();
  }
}