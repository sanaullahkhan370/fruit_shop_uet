import 'package:flutter/material.dart';
import '../core/api_service.dart';

class AdminScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Future<void> Function() onLogout;
  const AdminScreen({super.key, required this.user, required this.onLogout});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int page = 0;
  List<dynamic> products = [];
  List<dynamic> orders = [];
  List<dynamic> shops = [];
  bool loading = true;
  String? error;

  bool get superAdmin => widget.user['role'] == 'superAdmin';
  String? get shopId {
    final shop = widget.user['shop'];
    if (shop is Map) return shop['_id'];
    return shop?.toString();
  }

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      shops = await ApiService.shops();
      orders = await ApiService.orders();
      if (!superAdmin && shopId != null) products = await ApiService.products(shopId!);
    } catch (e) { error = e.toString(); }
    if (mounted) setState(() => loading = false);
  }

  Future<void> addProduct() async {
    final name = TextEditingController(), price = TextEditingController(), unit = TextEditingController(text: 'item'), description = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Add product/service'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 10),
        TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
        const SizedBox(height: 10),
        TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
        const SizedBox(height: 10),
        TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unit (item, kg, service)')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add'))],
    ));
    if (ok == true) {
      await ApiService.addProduct({'name': name.text, 'description': description.text, 'price': double.tryParse(price.text) ?? 0, 'unit': unit.text});
      await load();
    }
  }

  Future<void> addShop() async {
    final name = TextEditingController(), category = TextEditingController(), description = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Create shop'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Shop name')),
        const SizedBox(height: 10),
        TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
        const SizedBox(height: 10),
        TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create'))],
    ));
    if (ok == true) { await ApiService.createShop({'name': name.text, 'category': category.text, 'description': description.text}); await load(); }
  }

  Future<void> addAdmin(Map<String, dynamic> shop) async {
    final name = TextEditingController(), email = TextEditingController(), phone = TextEditingController(), password = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('Admin for ${shop['name']}'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Admin name')),
        const SizedBox(height: 10),
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 10),
        TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
        const SizedBox(height: 10),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create Admin'))],
    ));
    if (ok == true) { await ApiService.createShopAdmin(shop['_id'], {'name': name.text, 'email': email.text, 'phone': phone.text, 'password': password.text}); await load(); }
  }

  String? nextStatus(String status) => {'accepted': 'preparing', 'preparing': 'ready', 'ready': 'completed'}[status];

  Widget productPage() => ListView(padding: const EdgeInsets.all(16), children: [
    FilledButton.icon(onPressed: addProduct, icon: const Icon(Icons.add), label: const Text('Add product/service')),
    const SizedBox(height: 12),
    ...products.map((raw) {
      final p = Map<String, dynamic>.from(raw);
      return Card(child: ListTile(
        title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Rs. ${p['price']} / ${p['unit']}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Switch(value: p['isAvailable'] == true, onChanged: (v) async { await ApiService.updateProduct(p['_id'], {'isAvailable': v}); await load(); }),
          IconButton(onPressed: () async { await ApiService.deleteProduct(p['_id']); await load(); }, icon: const Icon(Icons.delete_outline, color: Colors.red)),
        ]),
      ));
    }),
  ]);

  Widget orderPage() => ListView(padding: const EdgeInsets.all(16), children: orders.map((raw) {
    final o = Map<String, dynamic>.from(raw);
    final next = nextStatus(o['status']);
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${o['orderNumber']} • ${o['customerName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
      Text('${o['phone']}\n${o['deliveryLocation']}'),
      const SizedBox(height: 8),
      ...List<dynamic>.from(o['items']).map((i) => Text('${i['quantity']} × ${i['name']}')),
      Text('Total: Rs. ${o['totalAmount']}'),
      const SizedBox(height: 8),
      if (o['status'] == 'pending') Row(children: [
        Expanded(child: OutlinedButton(onPressed: () async { await ApiService.orderStatus(o['_id'], 'rejected'); await load(); }, child: const Text('Reject'))),
        const SizedBox(width: 8),
        Expanded(child: FilledButton(onPressed: () async { await ApiService.orderStatus(o['_id'], 'accepted'); await load(); }, child: const Text('Accept'))),
      ]) else if (next != null) FilledButton(onPressed: () async { await ApiService.orderStatus(o['_id'], next); await load(); }, child: Text('Mark as $next')) else Chip(label: Text(o['status'])),
    ])));
  }).toList());

  Widget shopsPage() => ListView(padding: const EdgeInsets.all(16), children: [
    FilledButton.icon(onPressed: addShop, icon: const Icon(Icons.add_business), label: const Text('Add new shop')),
    const SizedBox(height: 12),
    ...shops.map((raw) {
      final s = Map<String, dynamic>.from(raw);
      return Card(child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.store)),
        title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(s['category']),
        trailing: FilledButton.tonal(onPressed: () => addAdmin(s), child: const Text('Create Admin')),
      ));
    }),
  ]);

  @override
  Widget build(BuildContext context) {
    final pages = superAdmin ? [shopsPage(), orderPage()] : [productPage(), orderPage()];
    return Scaffold(
      appBar: AppBar(title: Text(superAdmin ? 'UET Shops • Super Admin' : 'Shop Admin Dashboard'), actions: [
        IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
        IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout)),
      ]),
      body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Text(error!)) : pages[page],
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (v) => setState(() => page = v),
        destinations: [
          NavigationDestination(icon: Icon(superAdmin ? Icons.store : Icons.inventory_2), label: superAdmin ? 'Shops' : 'Products'),
          const NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
      ),
    );
  }
}
