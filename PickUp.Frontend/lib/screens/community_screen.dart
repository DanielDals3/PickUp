import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // Esempio di post della community (che arriveranno da Supabase)
  final List<Map<String, dynamic>> _posts = [
    {
      "user": "Alessandro B.",
      "sport": "Calcio a 5",
      "location": "Campo San Siro",
      "text": "Ci manca l'ultimo per stasera alle 21:00! Chi viene?",
      "time": "10 min fa",
      "needed": "1 giocatore",
      "isUrgent": true
    },
    {
      "user": "Giulia V.",
      "sport": "Tennis",
      "location": "Circolo Tennis",
      "text": "Cerco compagna per un set livello intermedio domani mattina.",
      "time": "1 ora fa",
      "needed": "1 socio",
      "isUrgent": false
    },
    {
      "user": "Roberto M.",
      "sport": "Padel",
      "location": "Padel Club",
      "text": "Siamo in 3, cerchiamo il quarto per un match combattuto!",
      "time": "2 ore fa",
      "needed": "1 giocatore",
      "isUrgent": false
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // Pulsante per creare un nuovo annuncio
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0), // Sopra la navbar
        child: FloatingActionButton.extended(
          onPressed: () {
            // Logica per nuovo post
          },
          label: const Text("Crea Post"),
          icon: const Icon(Icons.add_comment_rounded),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TITOLO GRANDE
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text(
                "Community",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),

            // 2. FILTRI RAPIDI PER SPORT
            _buildSportFilter(),

            const SizedBox(height: 10),

            // 3. FEED DEI POST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return _buildCommunityPost(_posts[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip("Tutti", true),
          _filterChip("Calcio", false),
          _filterChip("Padel", false),
          _filterChip("Tennis", false),
          _filterChip("Basket", false),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool value) {},
        backgroundColor: Colors.transparent,
        selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: StadiumBorder(side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!)),
      ),
    );
  }

  Widget _buildCommunityPost(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: Text(post['user'][0], style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post['user'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(post['time'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              if (post['isUrgent'])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                  child: const Text("URGENTE", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post['text'], style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(post['location'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text("Rispondi"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}