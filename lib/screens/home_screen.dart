import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'orders_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Future<void> Function() onLogout;
  const HomeScreen({super.key, required this.user, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = ApiService.shops();
  }

  IconData iconFor(String value) {
    final v = value.toLowerCase();
    if (v.contains('fruit')) return Icons.apple;
    if (v.contains('canteen')) return Icons.restaurant;
    if (v.contains('laundry')) return Icons.local_laundry_service;
    if (v.contains('barber')) return Icons.content_cut;
    return Icons.store;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UET Shops'),
        actions: [
          IconButton(tooltip: 'My orders', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())), icon: const Icon(Icons.receipt_long)),
          IconButton(tooltip: 'Logout', onPressed: widget.onLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => future = ApiService.shops()),
        child: FutureBuilder<List<dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return ListView(children: [const SizedBox(height: 180), Center(child: Text('Could not load shops\n${snapshot.error}', textAlign: TextAlign.center))]);
            final shops = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Welcome, ${widget.user['name']}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Text('Order from shops across UET campus'),
                const SizedBox(height: 18),
                if (shops.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No shops available yet'))),
                ...shops.map((raw) {
                  final shop = Map<String, dynamic>.from(raw);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(radius: 28, child: Icon(iconFor(shop['category'] ?? ''))),
                      title: Text(shop['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${shop['category']} • ${shop['isOpen'] == true ? 'Open' : 'Closed'}\n⭐ ${shop['rating'] ?? 0} (${shop['ratingCount'] ?? 0})'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: shop['isOpen'] == true ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopScreen(shop: shop, user: widget.user))) : null,
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
