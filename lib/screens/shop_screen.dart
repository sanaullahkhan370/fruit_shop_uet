import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  bool placingOrder = false;

  @override
  void initState() {
    super.initState();
    future = ApiService.products(widget.shop['_id']);
  }

  int quantity(String id) => cart[id] ?? 0;

  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Please turn on location/GPS and try again');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission is required for delivery');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is blocked. Enable it from app/browser settings');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> checkout(List<dynamic> products) async {
    if (placingOrder) return;
    setState(() => placingOrder = true);
    try {
      final position = await currentPosition();
      final latitude = position.latitude;
      final longitude = position.longitude;
      await ApiService.placeOrder({
        'shop': widget.shop['_id'],
        'items': products
            .where((p) => quantity(p['_id']) > 0)
            .map((p) => {'product': p['_id'], 'quantity': quantity(p['_id'])})
            .toList(),
        'phone': widget.user['phone'],
        'deliveryLocation': 'GPS location',
        'latitude': latitude,
        'longitude': longitude,
        'notes': '',
      });
      if (!mounted) return;
      setState(cart.clear);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order sent to shop admin successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => placingOrder = false);
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
                onPressed: placingOrder ? null : () => checkout(products),
                icon: placingOrder
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.shopping_cart_checkout),
                label: Padding(padding: const EdgeInsets.all(14), child: Text('Order $count item(s) • Rs. ${total.toStringAsFixed(0)}')),
              ),
            ),
          ),
        );
      },
    );
  }
}
