import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() => runApp(const MaterialApp(home: RickAndMortyApp()));

class RickAndMortyApp extends StatefulWidget {
  const RickAndMortyApp({super.key});

  @override
  State<RickAndMortyApp> createState() => _RickAndMortyAppState();
}

class _RickAndMortyAppState extends State<RickAndMortyApp> {
  String categoriaAtual = 'character';
  String titulo = 'Personagens';
  List dados = [];
  String? proximaPaginaUrl;
  bool carregandoMais = false;
  bool carregandoInicial = true;

  final ScrollController _scrollController = ScrollController();

  void salvarNoFirebase(dynamic item) async {
    var db = FirebaseFirestore.instance;

    try {
      await db.collection("favoritos").add({
        "nome": item['name'],
        "imagem": item['image'] ?? "",
        "tipo": categoriaAtual,
        "data": DateTime.now(),
      });

      print("Personagem salvo nos favoritos!");
    } catch (e) {
      print("Erro ao salvar: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    buscarDados(reset: true);
  }

  Future<void> buscarDados({bool reset = false}) async {
    if (reset) {
      setState(() {
        carregandoInicial = true;
        dados = [];
        proximaPaginaUrl = 'https://rickandmortyapi.com/api/$categoriaAtual';
      });
    } else {
      setState(() => carregandoMais = true);
    }

    try {
      final response = await http.get(Uri.parse(proximaPaginaUrl!));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          dados.addAll(json['results']);
          proximaPaginaUrl = json['info']['next'];
          carregandoInicial = false;
          carregandoMais = false;
        });
      }
    } catch (e) {
      debugPrint("Erro na API: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        actions: [
          _navButton('Personagens', 'character'),
          _navButton('Localizacoes', 'location'),
          _navButton('Episodios', 'episode'),
        ],
      ),
      body: carregandoInicial
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            controller: _scrollController,
            itemCount: proximaPaginaUrl == null ? dados.length : dados.length + 1,
            itemBuilder: (context, index) {
              if (index < dados.length) {
                final item = dados[index];
                return _buildTile(item);
              }
              return _buildLoadMoreButton();
            },
          ),
    );
  }

  Widget _buildLoadMoreButton() {
    if (proximaPaginaUrl == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: carregandoMais
          ? const Center(child: CircularProgressIndicator()) // Mostra a bolinha enquanto carrega
          : ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => buscarDados(), // Chama o carteiro manualmente!
              child: const Text("BUSCAR MAIS", style: TextStyle(color: Colors.white)),
            ),
    );
  }

  Widget _navButton(String label, String endpoint) {
    return TextButton(
      onPressed: () {
        categoriaAtual = endpoint;
        titulo = label;
        buscarDados(reset: true);
      },
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildTile(dynamic item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: categoriaAtual == 'character'
          ? Image.network(item['image'], width: 50)
          : const Icon(Icons.place),
        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        // ADICIONAMOS O BOTÃO AQUI:
        trailing: IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.red),
          onPressed: () {
            // Chamamos a função para salvar no Firebase
            salvarNoFirebase(item);
          },
        ),
      ),
    );
  }
}