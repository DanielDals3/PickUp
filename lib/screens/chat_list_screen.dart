import 'package:flutter/material.dart';
import 'package:pickup/screens/chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _activeFilter = "Tutti";
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Esempio di dati che poi arriveranno da Supabase
  final List<Map<String, dynamic>> _allChats = [
    {"name": "Calcetto Lunedì", "lastMsg": "Chi porta i fratini?", "time": "10:30", "unread": 3, "isGroup": true},
    {"name": "Marco Silva", "lastMsg": "Arrivo tra 5 minuti!", "time": "Ieri", "unread": 0, "isGroup": false},
    {"name": "Torneo Tennis", "lastMsg": "Partita confermata per le 18", "time": "Lun", "unread": 1, "isGroup": true},
  ];

  List<Map<String, dynamic>> get _filteredChats {
    Iterable<Map<String, dynamic>> list = _allChats;

    // 1. Filtro per tipologia (Gruppi/Privati)
    if (_activeFilter == "Gruppi") {
      return _allChats.where((chat) => chat['isGroup'] == true).toList();
    } else if (_activeFilter == "Privati") {
      return _allChats.where((chat) => chat['isGroup'] == false).toList();
    }

    // 2. Filtro per ricerca testuale
    if (_searchQuery.isNotEmpty) {
      list = list.where((chat) => 
        chat['name'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TITOLO GRANDE MODERNO
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text(
                "Messaggi",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),

            // BARRA DI RICERCA INTEGRATA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Cerca una chat...",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // FILTRI (Solo se non stiamo cercando, per pulizia)
            if (_searchQuery.isEmpty) _buildQuickFilters(),
            
            const SizedBox(height: 10),

            // LISTA CHAT
            Expanded(
              child: _filteredChats.isEmpty 
                ? _buildEmptyState() 
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100), // Spazio per la NavBar
                    itemCount: _filteredChats.length,
                    separatorBuilder: (context, index) => const Divider(indent: 80, height: 1),
                    itemBuilder: (context, index) {
                      final chat = _filteredChats[index];
                      return _buildChatTile(chat);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChip("Tutti"),
          _filterChip("Gruppi"),
          _filterChip("Privati"),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label), // Cambia il filtro al tocco
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    return ListTile(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatDetailScreen(chatName: chat['name'])),
        );
        if (mounted) setState(() => chat['unread'] = 0);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        child: Icon(
          chat['isGroup'] ? Icons.groups : Icons.person,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(chat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(chat['lastMsg'], maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(chat['time'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (chat['unread'] > 0)
            Container(
              margin: const EdgeInsets.only(top: 5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("${chat['unread']}", style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Nessuna conversazione in $_activeFilter", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}