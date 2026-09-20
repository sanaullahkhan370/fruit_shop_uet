import 'package:flutter/material.dart';
import '../core/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<dynamic>> future;
  @override
  void initState() { super.initState(); future = ApiService.orders(); }

  Color statusColor(String status) {
    if (status == 'completed') return Colors.green;
    if (status == 'rejected' || status == 'cancelled') return Colors.red;
    if (status == 'ready') return Colors.blue;
    return Colors.orange;
  }

  Future<void> rate(Map<String, dynamic> order) async {
    int rating = 5;
    final comment = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
      title: const Text('Rate your order'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(onPressed: () => setDialog(() => rating = i + 1), icon: Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber)))),
        TextField(controller: comment, decoration: const InputDecoration(labelText: 'Review')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit'))],
    )));
    if (ok == true) {
      try {
        await ApiService.review(order['_id'], rating, comment.text.trim());
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your review')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Orders')),
    body: RefreshIndicator(
      onRefresh: () async => setState(() => future = ApiService.orders()),
      child: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data ?? [];
          return ListView(padding: const EdgeInsets.all(16), children: orders.isEmpty
            ? [const Center(child: Padding(padding: EdgeInsets.all(50), child: Text('No orders yet')))]
            : orders.map((raw) {
                final o = Map<String, dynamic>.from(raw);
                final shop = o['shop'] is Map ? o['shop']['name'] : 'Shop';
                return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text(shop, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))), Chip(label: Text(o['status']), side: BorderSide.none, backgroundColor: statusColor(o['status']).withValues(alpha: .15))]),
                  Text('Order: ${o['orderNumber']}'),
                  ...List<dynamic>.from(o['items']).map((item) => Text('${item['quantity']} × ${item['name']}')),
                  const Divider(),
                  Text('Total: Rs. ${o['totalAmount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (o['status'] == 'completed') Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => rate(o), icon: const Icon(Icons.star), label: const Text('Rate order'))),
                ])));
              }).toList());
        },
      ),
    ),
  );
}
