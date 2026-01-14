import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.red),
      home: const PokemonListScreen(),
    );
  }
}

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});
  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  List<dynamic> pokemons = [];
  bool isLoading = true;
  bool isGridView = true;
  int offset = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!isLoading) fetchData(); // Load more เมื่อเกือบถึงขอบล่าง
      }
    });
  }

  Future<void> fetchData() async {
    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=20&offset=$offset');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          pokemons.addAll(jsonDecode(response.body)['results']);
          offset += 20;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PokéDex', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => isGridView = !isGridView),
          )
        ],
      ),
      body: pokemons.isEmpty && isLoading
          ? const Center(child: CircularProgressIndicator())
          : isGridView ? buildGridView() : buildListView(),
    );
  }

  Widget buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: pokemons.length,
      itemBuilder: (context, index) => PokemonCard(pokemon: pokemons[index], index: index, isGrid: true),
    );
  }

  Widget buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(10),
      itemCount: pokemons.length,
      itemBuilder: (context, index) => PokemonCard(pokemon: pokemons[index], index: index, isGrid: false),
    );
  }
}

class PokemonCard extends StatelessWidget {
  final dynamic pokemon;
  final int index;
  final bool isGrid;

  const PokemonCard({super.key, required this.pokemon, required this.index, required this.isGrid});

  @override
  Widget build(BuildContext context) {
    final String name = pokemon['name'];
    final String url = pokemon['url'];
    final String id = url.split('/')[url.split('/').length - 2];
    final String imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PokemonDetailScreen(name: name, url: url, imageUrl: imageUrl, id: id)),
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: isGrid ? _buildGridItem(id, name, imageUrl) : _buildListItem(id, name, imageUrl),
      ),
    );
  }

  Widget _buildGridItem(String id, String name, String imageUrl) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('#${id.padLeft(3, '0')}', style: const TextStyle(color: Colors.grey)),
        Expanded(child: Hero(tag: 'poke-$id', child: Image.network(imageUrl))),
        Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildListItem(String id, String name, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Text('#${id.padLeft(3, '0')}', style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(width: 20),
          Hero(tag: 'poke-$id', child: Image.network(imageUrl, width: 80, height: 80)),
          const SizedBox(width: 20),
          Text(name.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}

class PokemonDetailScreen extends StatefulWidget {
  final String name, url, imageUrl, id;
  const PokemonDetailScreen({super.key, required this.name, required this.url, required this.imageUrl, required this.id});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  Map<String, dynamic>? detail;

  @override
  void initState() {
    super.initState();
    http.get(Uri.parse(widget.url)).then((res) {
      if (mounted) setState(() => detail = jsonDecode(res.body));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name.toUpperCase()), backgroundColor: Colors.red, foregroundColor: Colors.white),
      body: detail == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Hero(tag: 'poke-${widget.id}', child: Image.network(widget.imageUrl, height: 250)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: (detail!['types'] as List).map((t) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                      child: Text(t['type']['name'].toString().toUpperCase(), style: const TextStyle(color: Colors.white)),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text("BASE STATS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Divider()),
                  ... (detail!['stats'] as List).map((s) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 90, child: Text(s['stat']['name'].toString().toUpperCase(), style: const TextStyle(fontSize: 12))),
                        Expanded(child: LinearProgressIndicator(value: s['base_stat'] / 160, color: Colors.green, minHeight: 8)),
                        const SizedBox(width: 10),
                        Text('${s['base_stat']}'),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
    );
  }
}