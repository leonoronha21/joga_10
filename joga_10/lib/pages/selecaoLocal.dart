import 'package:flutter/material.dart';

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
          QuadraItem(),
          QuadraItem(),

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
          QuadraItem(),
          QuadraItem(),
          QuadraItem(),
          QuadraItem(),
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
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(
        'https://static.vecteezy.com/ti/vetor-gratis/p1/2871329-design-dees-de-campo-verde-de-futebol-e-futebol-gratis-vetor.jpg',
        width: 80,
        height: 80,
      ),
      title: Text(
        'Nome da Quadra',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        'Preço: R\$ 50/hora',
        style: TextStyle(color: Colors.white),
      ),
      trailing: ElevatedButton(
        onPressed: () {
          // Ação de reserva da quadra
          // Implemente a lógica de reserva aqui
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HorariosDisponiveisPage()),
          );
        },
        child: Text(
          'Reservar',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class HorariosDisponiveisPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
        title: Text('Horários Disponíveis', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
      ),
      body: ListView.builder(
        itemCount: 25, // Para representar horários de 00hrs a 24hrs
        itemBuilder: (context, index) {
          final hour = index < 10 ? '0$index:00' : '$index:00';
          return ListTile(
            title: Text(
              hour,
              style: TextStyle(color: Colors.white),
            ),
            // Adicione aqui a lógica para reservar o horário
            trailing: ElevatedButton(
              onPressed: () {
                // Lógica de reserva do horário
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
