import 'package:flutter/material.dart';
import 'package:joga_10/pages/criarPartida.dart';

void main() {
  runApp(MaterialApp(
    home: SelecionaLocalPage(),
  ));
}

class SelecionaLocalPage extends StatelessWidget {
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
          // Detalhes do Primeiro Local
          LocalItem(
            nome: 'Local 1',
            descricao: 'Descrição do Local 1',
            endereco: 'Endereço do Local 1',
            contato: 'Contato do Local 1',
            cidade: 'Cidade do Local 1',
            quantidadeQuadras: '2',
            preco: 'R\$ 50/hora',
          ),
          // Quadras do Primeiro Local
          QuadraItem(nomeQuadra: 'Quadra A', precoQuadra: 'R\$ 50/hora'),
          QuadraItem(nomeQuadra: 'Quadra B', precoQuadra: 'R\$ 50/hora'),

          // Detalhes do Segundo Local
          LocalItem(
            nome: 'Local 2',
            descricao: 'Descrição do Local 2',
            endereco: 'Endereço do Local 2',
            contato: 'Contato do Local 2',
            cidade: 'Cidade do Local 2',
            quantidadeQuadras: '4',
            preco: 'R\$ 60/hora',
          ),
          // Quadras do Segundo Local
          QuadraItem(nomeQuadra: 'Quadra X', precoQuadra: 'R\$ 60/hora'),
          QuadraItem(nomeQuadra: 'Quadra Y', precoQuadra: 'R\$ 60/hora'),
          QuadraItem(nomeQuadra: 'Quadra Z', precoQuadra: 'R\$ 60/hora'),
          QuadraItem(nomeQuadra: 'Quadra W', precoQuadra: 'R\$ 60/hora'),
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
        Divider(), // Linha separadora
      ],
    );
  }
}

class QuadraItem extends StatelessWidget {
  final String nomeQuadra;
  final String precoQuadra;

  QuadraItem({
    required this.nomeQuadra,
    required this.precoQuadra,
  });

  void reservarQuadra(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HorariosDisponiveisPage(
          nomeQuadra: nomeQuadra,
          precoQuadra: precoQuadra, selectedTime: '', selectedLocation: '',
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
          reservarQuadra(context); // Chame a função de reserva ao clicar no botão
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
  final String selectedLocation; // Adicione este parâmetro
  final String selectedTime; // Adicione este parâmetro

  HorariosDisponiveisPage({
    required this.nomeQuadra,
    required this.precoQuadra,
    required this.selectedLocation, // Passe o local selecionado
    required this.selectedTime, // Passe o horário selecionado
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
                // Passar informações para a página CriarPartidaPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CriarPartidaPage(
                      selectedLocation: selectedLocation, // Passe o local selecionado
                      selectedTime: hour, // Passe o horário selecionado
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
