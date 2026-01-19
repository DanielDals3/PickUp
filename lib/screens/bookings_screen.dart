import 'package:flutter/material.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TITOLO GRANDE MODERNO
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text(
                "Prenotazioni",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),

            // 2. TAB SELECTOR (Attive vs Passate)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: "In programma"),
                  Tab(text: "Storico"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 3. CONTENUTO DELLE TAB
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingsList(isActive: true),
                  _buildBookingsList(isActive: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList({required bool isActive}) {
    // Dati fittizi per l'esempio
    final bookings = isActive 
      ? [
          {"court": "Stella Azzurra", "sport": "Calcio a 5", "date": "Oggi", "time": "20:30", "status": "Confermata"},
          {"court": "Padel Hub", "sport": "Padel", "date": "Domani", "time": "18:00", "status": "In attesa"},
        ]
      : [
          {"court": "Tennis Club Roma", "sport": "Tennis", "date": "12 Gen", "time": "10:00", "status": "Giocata"},
        ];

    if (bookings.isEmpty) {
      return Center(
        child: Text("Nessuna prenotazione", style: TextStyle(color: Colors.grey[600])),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final item = bookings[index];
        return _buildBookingCard(item, isActive);
      },
    );
  }

  Widget _buildBookingCard(Map<String, String> item, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icona Sport
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item['sport'] == "Padel" ? Icons.sports_tennis : Icons.sports_soccer,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            
            // Info Prenotazione
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['court']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item['date']} • ${item['time']}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(item['status']!).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item['status']!,
                style: TextStyle(
                  color: _getStatusColor(item['status']!),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Confermata": return Colors.green;
      case "In attesa": return Colors.orange;
      case "Giocata": return Colors.blue;
      default: return Colors.grey;
    }
  }
}