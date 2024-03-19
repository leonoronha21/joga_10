import 'package:flutter/material.dart';
import 'package:joga_10/pages/login_page.dart';
import 'package:joga_10/pages/pagina1.dart';
import 'dados_cadastrais.dart';
import 'pagina2.dart';
import 'pagina3.dart';

class MainPage extends StatefulWidget {
  
  final Map<String, dynamic> userData;
  MainPage({required this.userData});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  PageController controller = PageController(initialPage: 0);
  int posicaoPagina = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
           key: appKey,
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
        appBar: AppBar(
            backgroundColor: Color.fromARGB(68, 56, 25, 139),
            title: Image.asset(
              'lib/assets/img/Joga_transparente.png',
              width: 120, // AjustA a largura conforme necessário
            ),
            centerTitle: true, // Centraliza a imagem no AppBar
          ),
          
        drawer: Drawer(
        
          child: Column(
           
                    children: [       
                               
                      UserAccountsDrawerHeader( 
                                                                    
                      accountName: Text(widget.userData['nome']+' '+widget.userData['sobrenome']), // Nome do usuário
                     accountEmail: Text(widget.userData['sub']), // Email do usuário
                      decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                                color: Color.fromARGB(255, 0, 10,80), // Cor de fundo do quadrado
                        ), // Email do usuário
                      currentAccountPicture: CircleAvatar(
                        // Foto do usuário
                        backgroundImage: AssetImage("lib/assets/img/volei.png"),
                      ),
                    ),
             /* Expanded(
                
                child: ListView(
                  
                  children: [
                    ListTile(
                      title: Text("Amigo 1"),
                      leading: Icon(Icons.person), // Ícone de amigo
                      onTap: () {
                        // Ação a ser executada quando o amigo 1 é selecionado
                      },
                    ),
                    ListTile(
                      title: Text("Amigo 2"),
                      leading: Icon(Icons.person), // Ícone de amigo
                      onTap: () {
                        // Ação a ser executada quando o amigo 2 é selecionado
                      },
                    ),
                    // Adicione mais amigos conforme necessário
                  ],
                ),
              ),*/
              ListTile(
                
                title: Text("Dados pessoais"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DadosCadastraisPage(userData: widget.userData),
                    ),
                  );
                },
              ),
              ListTile(
                //title: Text("Trocar Senha"),
                onTap: () {
                  // Ação a ser executada quando "Configurações" é selecionado
                },
              ),
              ListTile(
                title: Text("Sair"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView(
                physics: NeverScrollableScrollPhysics(),
                
                controller: controller,
                onPageChanged: (value) {
                  setState(() {
                    posicaoPagina = value;
                  });
                },
                children:  [
                  Pagina1Page(userData: widget.userData),
                  Pagina2Page(userData: widget.userData),
                  Pagina3Page(userData: widget.userData),
                ],
              ),
            ),
            BottomNavigationBar(
              onTap: (value) {
                controller.jumpToPage(value);
              },
              currentIndex: posicaoPagina,
              items: const [
                BottomNavigationBarItem(
                  label: "Home",
                  icon: Icon(Icons.home),
                ),
                BottomNavigationBarItem(
                  label: "Buscar partida",
                  icon: Icon(Icons.search),
                ),
                BottomNavigationBarItem(
                  label: "Contate-nos",
                  icon: Icon(Icons.markunread_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


