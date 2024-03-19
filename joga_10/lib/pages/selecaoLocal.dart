import 'package:flutter/material.dart';
import 'package:joga_10/model/Quadras.dart';
import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/pages/criarPartida.dart';
import 'package:joga_10/service/EstabelecimentoService.dart';
import 'package:joga_10/service/QuadraService.dart';

class SelecionaLocalPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  SelecionaLocalPage({Key? key, required this.userData}) : super(key: key);

  @override
  _SelecionaLocalPageState createState() => _SelecionaLocalPageState();
}

class _SelecionaLocalPageState extends State<SelecionaLocalPage> {
  late Future<List<Estabelecimentos>> estabelecimentos;
  late Future<List<Quadras>> quadras;

  @override
  void initState() {
    super.initState();
    estabelecimentos = EstabelecimentoService().getAllEstabelecimentos();
    quadras = QuadraService().getAllQuadras();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
        title: Text(
          'Locais Disponíveis',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder(
        future: Future.wait([estabelecimentos, quadras]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Erro: ${snapshot.error}');
          } else {
            try {
              List<Estabelecimentos> estabelecimentosList = snapshot.data?[0] ?? [];
              List<Quadras> quadrasList = snapshot.data?[1] ?? [];

              return ListView.separated(
                itemCount: estabelecimentosList.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  Estabelecimentos estabelecimento = estabelecimentosList[index];

                 
                  Widget localItem = LocalItem(
                    nome: estabelecimento.nome,
                    descricao: estabelecimento.razaoSocial,
                    endereco:
                        '${estabelecimento.rua}, ${estabelecimento.numero} - ${estabelecimento.bairro}, ${estabelecimento.cidade}',
                    contato: estabelecimento.telefone,
                    cidade: estabelecimento.cidade,
                    quantidadeQuadras: quadrasList
                        .where((quadra) =>
                            quadra.idEstabelecimento ==
                            estabelecimento.id)
                        .length
                        .toString(),
                   
                  );

               
                  List<QuadraItem> quadrasWidgets = quadrasList
                      .where((quadra) =>
                          quadra.idEstabelecimento ==
                          estabelecimento.id)
                      .map((quadra) => QuadraItem(
                            nomeQuadra: quadra.nome,
                            precoQuadra: quadra.preco,
                            nomeLocal: estabelecimento.nome,
                            userData: widget.userData,
                          ))
                      .toList();

               
                  return Column(
                    children: [
                      localItem,
                      ...quadrasWidgets,
                    ],
                  );
                },
              );
            } catch (e) {
              print('Erro durante a construção da interface: $e');
              return Text('Erro durante a construção da interface: $e');
            }
          }
        },
      ),
    );
  }
}


class LocalItem extends StatelessWidget {
  final String nome;
  final String descricao;
  final String endereco;
  final String contato;
  final String cidade;
  final String quantidadeQuadras;


  LocalItem({
    required this.nome,
    required this.descricao,
    required this.endereco,
    required this.contato,
    required this.cidade,
    required this.quantidadeQuadras,
 
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text('Nome: '+
            nome,
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text('Descricao: '+
            descricao,
            style: TextStyle(color: Colors.white),
          ),
        ),
        ListTile(
          title: Text('Endereço: '+
            endereco,
            style: TextStyle(color: Colors.white),
          ),
        ),
        ListTile(
          title: Text('Telefone: '+
            contato,
            style: TextStyle(color: Colors.white),
          ),
        ),
        ListTile(
          title: Text('Cidade: '+
            cidade,
            style: TextStyle(color: Colors.white),
          ),
        ),
        ListTile(
          title: Text(
            'Quantidade de Quadras: $quantidadeQuadras disponíveis',
            style: TextStyle(color: Colors.white),
          ),
        ),
        
        Divider(),
      ],
    );
  }
}
String getIconPath(String quadraNome) {
  if (quadraNome.toLowerCase().contains('basquete')) {
    return 'lib/assets/img/quadra-de-basquete.png';
  } else if (quadraNome.toLowerCase().contains('futebol')) {
    return 'lib/assets/img/futebol.png';
  } else if (quadraNome.toLowerCase().contains('volei')) {
    return 'lib/assets/img/voleibol.png';
  } else if (quadraNome.toLowerCase().contains('futevolei')) {
    return 'lib/assets/img/voleibol.png';
  } else if (quadraNome.toLowerCase().contains('tenis')) {
    return 'lib/assets/img/quadra-de-tenis.png';
  } else {
    return 'lib/assets/img/futebol.png';
  }
}

class QuadraItem extends StatelessWidget {
  final String nomeQuadra;
  final String precoQuadra;
  final String nomeLocal;
  final Map<String, dynamic> userData;

  QuadraItem({
    required this.nomeQuadra,
    required this.precoQuadra,
    required this.nomeLocal,
    required this.userData,
  });

  void reservarQuadra(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HorariosDisponiveisPage(
          nomeQuadra: nomeQuadra,
          precoQuadra: precoQuadra,
          nomeLocal: nomeLocal,
          selectedTime: '',
          userData: userData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String iconPath = getIconPath(nomeQuadra);

    return ListTile(
      leading: Image.asset(
        iconPath,
        width: 100,
        height: 200,
      ),
      title: Text(
        nomeQuadra,
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        'Preço: $precoQuadra',
        style: TextStyle(color: Colors.white),
      ),
      trailing: ElevatedButton(
        onPressed: () {
          reservarQuadra(context);
        },
        child: Text(
          'Horários',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class HorariosDisponiveisPage extends StatelessWidget {
  final String nomeQuadra;
  final String precoQuadra;
  final String nomeLocal;
  final String selectedTime;
  final Map<String, dynamic> userData;

  HorariosDisponiveisPage({
    required this.nomeQuadra,
    required this.precoQuadra,
    required this.nomeLocal,
    required this.selectedTime,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
        title: Text('Horários Disponíveis', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
      ),
      body: ListView.builder(
        itemCount: 25,
        itemBuilder: (context, index) {
          final hour = index < 10 ? '0$index:00' : '$index:00';
          return ListTile(
            title: Text(
              hour,
              style: TextStyle(color: Colors.white),
            ),
            trailing: ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CriarPartidaPage(
          
          selectedLocation: nomeQuadra,
          selectedTime: hour,
          price: precoQuadra,
          estabelecimento: nomeLocal,
          userData: userData,
        ),
      ),
    );
  },
  child: Text(
    'Reservar',
    style: TextStyle(color: Colors.white),
  ),
),
          );
        },
      ),
    );
  }
}
