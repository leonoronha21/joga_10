import 'package:flutter/material.dart';
import 'package:joga_10/pages/criarPartida.dart';

class SelecionaLocalPage extends StatelessWidget {
    final Map<String, dynamic> userData;

  SelecionaLocalPage({Key? key, required this.userData}) : super(key: key);
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
      body: ListView(
        children: <Widget>[
          LocalItem(
            nome: 'Local 1',
            descricao: 'Descrição do Local 1',
            endereco: 'Endereço do Local 1',
            contato: 'Contato do Local 1',
            cidade: 'Cidade do Local 1',
            quantidadeQuadras: '2',
            preco: 'R\$ 50/hora',
          ),
          QuadraItem(
            nomeQuadra: 'Quadra A',
            precoQuadra: 'R\$ 50/hora',
            nomeLocal: 'Local 1',
            userData: userData,
          ),
          QuadraItem(
            nomeQuadra: 'Quadra B',
            precoQuadra: 'R\$ 50/hora',
            nomeLocal: 'Local 1',
            userData: userData,
          ),
          LocalItem(
            nome: 'Local 2',
            descricao: 'Descrição do Local 2',
            endereco: 'Endereço do Local 2',
            contato: 'Contato do Local 2',
            cidade: 'Cidade do Local 2',
            quantidadeQuadras: '4',
            preco: 'R\$ 60/hora',
          ),
          QuadraItem(
            nomeQuadra: 'Quadra X',
            precoQuadra: 'R\$ 60/hora',
            nomeLocal: 'Local 2',
            userData: userData,
          ),
          QuadraItem(
            nomeQuadra: 'Quadra Y',
            precoQuadra: 'R\$ 60/hora',
            nomeLocal: 'Local 2',
            userData: userData,
          ),
          QuadraItem(
            nomeQuadra: 'Quadra Z',
            precoQuadra: 'R\$ 60/hora',
            nomeLocal: 'Local 2',
            userData: userData,
          ),
          QuadraItem(
            nomeQuadra: 'Quadra W',
            precoQuadra: 'R\$ 60/hora',
            nomeLocal: 'Local 2',
            userData: userData,
          ),
        ],
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
  final String preco;

  LocalItem({
    required this.nome,
    required this.descricao,
    required this.endereco,
    required this.contato,
    required this.cidade,
    required this.quantidadeQuadras,
    required this.preco,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(
            nome,
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            descricao,
            style: TextStyle(color: Colors.white),
          ),
        ),
        ListTile(
          title: Text(
            endereco,
            style: TextStyle(color: Colors.white),
          ),
        ),
        ListTile(
          title: Text(
            contato,
            style: TextStyle(color: Colors.white),
          ),
        ),
        ListTile(
          title: Text(
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
        ListTile(
          title: Text(
            'Preço: $preco',
            style: TextStyle(color: Colors.white),
          ),
        ),
        Divider(),
      ],
    );
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
    return ListTile(
      leading: Image.network(
        'https://static.vecteezy.com/ti/vetor-gratis/p1/2871329-design-dees-de-campo-verde-de-futebol-e-futebol-gratis-vetor.jpg',
        width: 80,
        height: 80,
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
