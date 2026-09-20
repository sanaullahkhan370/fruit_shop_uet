import 'package:flutter/material.dart';
import '../core/api_service.dart';

class ShopScreen extends StatefulWidget {
  final Map<String, dynamic> shop;
  final Map<String, dynamic> user;
  const ShopScreen({super.key, required this.shop, required this.user});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late Future<List<dynamic>> future;
  final Map<String, int> cart = {};

  @override
  void initState() {
    super.initState();
    future = ApiService.products(widget.shop['_id']);
  }

  int quantity(String id) => cart[id] ?? 0;

  Future<void> checkout(List<dynamic> products) async {
    final location = TextEditingController();
    final notes = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Place order'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: location,
              decoration: const InputDecoration(labelText: 'Delivery/Pickup location'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Location is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Notes are required' : null,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(context, true); }, child: const Text('Confirm')),
        ],
      ),
    );
    if (approved != true) return;
    try {
      await ApiService.placeOrder({
        'shop': widget.shop['_id'],
        'items': products.where((p) => quantity(p['_id']) > 0).map((p) => {'product': p['_id'], 'quantity': quantity(p['_id'])}).toList(),
        'phone': widget.user['phone'],
        'deliveryLocation': location.text.trim(),
        'notes': notes.text.trim(),
      });
      if (!mounted) return;
      setState(cart.clear);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final count = cart.values.fold<int>(0, (a, b) => a + b);
        final total = products.fold<double>(0, (sum, p) => sum + ((p['price'] as num?)?.toDouble() ?? 0) * quantity(p['_id']));
        return Scaffold(
          appBar: AppBar(title: Text(widget.shop['name'] ?? 'Shop')),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(widget.shop['description'] ?? '', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    if (products.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No products available'))),
                    ...products.map((raw) {
                      final p = Map<String, dynamic>.from(raw);
                      final id = p['_id'] as String;
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
                          title: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${p['description'] ?? ''}\nRs. ${p['price']} / ${p['unit']}'),
                          isThreeLine: true,
                          trailing: p['isAvailable'] != true ? const Text('Unavailable') : Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(onPressed: quantity(id) == 0 ? null : () => setState(() => cart[id] = quantity(id) - 1), icon: const Icon(Icons.remove_circle_outline)),
                            Text('${quantity(id)}'),
                            IconButton(onPressed: () => setState(() => cart[id] = quantity(id) + 1), icon: const Icon(Icons.add_circle)),
                          ]),
                        ),
                      );
                    }),
                  ],
                ),
          bottomNavigationBar: count == 0 ? null : SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: () => checkout(products),
                icon: const Icon(Icons.shopping_cart_checkout),
                label: Padding(padding: const EdgeInsets.all(14), child: Text('Order $count item(s) • Rs. ${total.toStringAsFixed(0)}')),
              ),
            ),
          ),
        );
      },
    );
  }
}
