import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
  Map<String, dynamic> currentUser = {};
  bool loading = true;
  bool togglingShop = false;
  String? error;

  bool get superAdmin => widget.user['role'] == 'superAdmin';
  String? get shopId {
    final shop = (currentUser.isEmpty ? widget.user : currentUser)['shop'];
    if (shop is Map) return shop['_id'];
    return shop?.toString();
  }

  @override
  void initState() {
    super.initState();
    currentUser = Map<String, dynamic>.from(widget.user);
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      currentUser = await ApiService.me();
      shops = await ApiService.shops();
      orders = await ApiService.orders();
      if (!superAdmin && shopId != null) products = await ApiService.products(shopId!);
    } catch (e) { error = e.toString(); }
    if (mounted) setState(() => loading = false);
  }

  Future<void> addProduct() async {
    final name = TextEditingController();
    final price = TextEditingController();
    final unit = TextEditingController(text: 'item');
    final description = TextEditingController();
    String imageData = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add product/service'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              imagePickerField(
                label: 'Item picture (optional)',
                value: imageData,
                icon: Icons.inventory_2_outlined,
                onChanged: (value) => setDialogState(() => imageData = value),
              ),
              const SizedBox(height: 10),
              TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
              const SizedBox(height: 10),
              TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unit (item, kg, service)')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    if (ok == true) {
      await ApiService.addProduct({
        'name': name.text,
        'description': description.text,
        'imageUrl': imageData,
        'price': double.tryParse(price.text) ?? 0,
        'unit': unit.text,
      });
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

  Future<void> editShop(Map<String, dynamic> shop) async {
    final name = TextEditingController(text: shop['name']?.toString() ?? '');
    final category = TextEditingController(text: shop['category']?.toString() ?? '');
    final description = TextEditingController(text: shop['description']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update shop'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Shop name')),
            const SizedBox(height: 10),
            TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: 10),
            TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.updateShop(shop['_id'], {
          'name': name.text.trim(),
          'category': category.text.trim(),
          'description': description.text.trim(),
        });
        await load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop updated')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> deleteShop(Map<String, dynamic> shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete shop?'),
        content: Text('Are you sure you want to delete "${shop['name']}"? Existing order history will remain safe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService.deleteShop(shop['_id']);
        await load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop deleted')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> editAdmin(Map<String, dynamic> shop) async {
    try {
      final admin = await ApiService.shopAdmin(shop['_id']);
      if (!mounted) return;
      final name = TextEditingController(text: admin['name']?.toString() ?? '');
      final email = TextEditingController(text: admin['email']?.toString() ?? '');
      final phone = TextEditingController(text: admin['phone']?.toString() ?? '');
      final password = TextEditingController();
      String profileImage = admin['profileImageUrl']?.toString() ?? '';
      bool hidePassword = true;

      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Admin account • ${shop['name']}'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                imagePickerField(
                  label: 'Admin picture (optional)',
                  value: profileImage,
                  icon: Icons.person,
                  onChanged: (value) => setDialogState(() => profileImage = value),
                ),
                const SizedBox(height: 10),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Admin name')),
                const SizedBox(height: 10),
                TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Login email')),
                const SizedBox(height: 10),
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 10),
                TextField(
                  controller: password,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: 'New password (optional)',
                    helperText: 'Leave empty to keep current password',
                    suffixIcon: IconButton(
                      onPressed: () => setDialogState(() => hidePassword = !hidePassword),
                      icon: Icon(hidePassword ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Update Account')),
            ],
          ),
        ),
      );

      if (ok == true) {
        final body = <String, dynamic>{
          'name': name.text.trim(),
          'email': email.text.trim(),
          'phone': phone.text.trim(),
          'profileImageUrl': profileImage,
        };
        if (password.text.isNotEmpty) body['password'] = password.text;
        await ApiService.updateShopAdmin(shop['_id'], body);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin account updated')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> addAdmin(Map<String, dynamic> shop) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController();
    String profileImage = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Admin for ${shop['name']}'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              imagePickerField(
                label: 'Admin picture (optional)',
                value: profileImage,
                icon: Icons.person,
                onChanged: (value) => setDialogState(() => profileImage = value),
              ),
              const SizedBox(height: 10),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Admin name')),
              const SizedBox(height: 10),
              TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 10),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 10),
              TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Create Admin')),
          ],
        ),
      ),
    );
    if (ok == true) {
      await ApiService.createShopAdmin(shop['_id'], {
        'name': name.text,
        'email': email.text,
        'phone': phone.text,
        'profileImageUrl': profileImage,
        'password': password.text,
      });
      await load();
    }
  }

  Future<void> editProduct(Map<String, dynamic> product, {bool refreshDashboard = true}) async {
    final name = TextEditingController(text: product['name']?.toString() ?? '');
    final description = TextEditingController(text: product['description']?.toString() ?? '');
    final price = TextEditingController(text: product['price']?.toString() ?? '');
    final unit = TextEditingController(text: product['unit']?.toString() ?? 'item');
    String imageData = product['imageUrl']?.toString() ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update product/service'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              imagePickerField(
                label: 'Item picture (optional)',
                value: imageData,
                icon: Icons.inventory_2_outlined,
                onChanged: (value) => setDialogState(() => imageData = value),
              ),
              const SizedBox(height: 10),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
              const SizedBox(height: 10),
              TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unit')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Update')),
          ],
        ),
      ),
    );
    if (ok == true) {
      await ApiService.updateProduct(product['_id'], {
        'name': name.text.trim(),
        'description': description.text.trim(),
        'imageUrl': imageData,
        'price': double.tryParse(price.text) ?? 0,
        'unit': unit.text.trim(),
      });
      if (refreshDashboard) await load();
    }
  }

  Future<String?> pickImageAction(String current) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(sheetContext, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(sheetContext, 'camera'),
          ),
          if (current.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove picture'),
              onTap: () => Navigator.pop(sheetContext, 'remove'),
            ),
        ]),
      ),
    );
    if (action == null) return null;
    if (action == 'remove') return '';
    final source = action == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 65,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > 1400000) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Picture is too large. Please choose a smaller picture.')));
      return null;
    }
    final mime = file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  Widget imagePickerField({
    required String label,
    required String value,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Row(children: [
      imageOrPlaceholder(value, icon, size: 72),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () async {
            final selected = await pickImageAction(value);
            if (selected != null) onChanged(selected);
          },
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(value.isEmpty ? label : 'Change picture'),
        ),
      ),
    ]);
  }

  ImageProvider? imageProviderFor(String? value) {
    final source = value?.trim() ?? '';
    if (source.isEmpty) return null;
    if (source.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(source.split(',').last));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(source);
  }

  Widget imageOrPlaceholder(String? url, IconData icon, {double size = 56}) {
    final value = url?.trim() ?? '';
    final provider = imageProviderFor(value);
    if (provider == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image(
        image: provider,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Future<void> customizeShop() async {
    final shop = currentUser['shop'];
    if (shop is! Map || shopId == null) return;
    String background = shop['backgroundImageUrl']?.toString() ?? '';
    String profile = currentUser['profileImageUrl']?.toString() ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Shop appearance'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              imagePickerField(
                label: 'Background picture (optional)',
                value: background,
                icon: Icons.storefront,
                onChanged: (value) => setDialogState(() => background = value),
              ),
              const SizedBox(height: 16),
              imagePickerField(
                label: 'Admin picture (optional)',
                value: profile,
                icon: Icons.person,
                onChanged: (value) => setDialogState(() => profile = value),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        await ApiService.updateShop(shopId!, {'backgroundImageUrl': background});
        currentUser = await ApiService.updateMe({'profileImageUrl': profile});
        await load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop appearance updated')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Widget shopHeader() {
    final shop = currentUser['shop'];
    final data = shop is Map ? shop : <String, dynamic>{};
    final background = data['backgroundImageUrl']?.toString().trim() ?? '';
    final profile = currentUser['profileImageUrl']?.toString() ?? '';
    final backgroundProvider = imageProviderFor(background);
    return Container(
      height: 150,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.primary,
        image: backgroundProvider == null
            ? null
            : DecorationImage(
                image: backgroundProvider,
                fit: BoxFit.cover,
                onError: (_, __) {},
              ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [Colors.black.withValues(alpha: 0.62), Colors.black.withValues(alpha: 0.12)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          ClipOval(child: imageOrPlaceholder(profile, Icons.person, size: 64)),
          const SizedBox(width: 14),
          Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['name']?.toString() ?? 'My Shop', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(currentUser['name']?.toString() ?? 'Shop Admin', style: const TextStyle(color: Colors.white70)),
          ])),
          IconButton.filledTonal(onPressed: customizeShop, tooltip: 'Change pictures', icon: const Icon(Icons.photo_camera_outlined)),
        ]),
      ),
    );
  }

  String? nextStatus(String status) => {'accepted': 'preparing', 'preparing': 'ready', 'ready': 'completed'}[status];

  Future<void> toggleShopOpen(bool value) async {
    if (shopId == null || togglingShop) return;
    setState(() => togglingShop = true);
    try {
      await ApiService.updateShop(shopId!, {'isOpen': value});
      currentUser = await ApiService.me();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? 'Shop is now OPEN' : 'Shop is now CLOSED')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => togglingShop = false);
    }
  }

  Widget shopStatusControl() {
    final shop = currentUser['shop'];
    final data = shop is Map ? shop : <String, dynamic>{};
    final isOpen = data['isOpen'] == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFE7FFF4) : const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOpen ? const Color(0xFF73D9AD) : const Color(0xFFFFAAAA),
        ),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isOpen ? const Color(0xFF0A8F5C) : const Color(0xFFC63838),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            isOpen ? Icons.storefront_rounded : Icons.storefront_outlined,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isOpen ? 'Shop is Open' : 'Shop is Closed',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              isOpen
                  ? 'Customers can view items and place orders'
                  : 'Customers cannot place orders',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ]),
        ),
        if (togglingShop)
          const Padding(
            padding: EdgeInsets.all(10),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          Switch(
            value: isOpen,
            onChanged: toggleShopOpen,
          ),
      ]),
    );
  }

  Widget productPage() => ListView(padding: const EdgeInsets.all(16), children: [
    shopHeader(),
    shopStatusControl(),
    const SizedBox(height: 10),
    OutlinedButton.icon(onPressed: customizeShop, icon: const Icon(Icons.image_outlined), label: const Text('Background & admin picture')),
    const SizedBox(height: 10),
    FilledButton.icon(onPressed: addProduct, icon: const Icon(Icons.add), label: const Text('Add product/service')),
    const SizedBox(height: 12),
    ...products.map((raw) {
      final p = Map<String, dynamic>.from(raw);
      return Card(child: ListTile(
        leading: imageOrPlaceholder(p['imageUrl']?.toString(), Icons.inventory_2_outlined),
        title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Rs. ${p['price']} / ${p['unit']}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(tooltip: 'Update item and picture', onPressed: () => editProduct(p), icon: const Icon(Icons.edit_outlined)),
          Switch(value: p['isAvailable'] == true, onChanged: (v) async { await ApiService.updateProduct(p['_id'], {'isAvailable': v}); await load(); }),
          IconButton(onPressed: () async { await ApiService.deleteProduct(p['_id']); await load(); }, icon: const Icon(Icons.delete_outline, color: Colors.red)),
        ]),
      ));
    }),
  ]);

  Future<void> openDeliveryLocation(dynamic latitude, dynamic longitude) async {
    final lat = latitude is num ? latitude.toDouble() : double.tryParse(latitude?.toString() ?? '');
    final lng = longitude is num ? longitude.toDouble() : double.tryParse(longitude?.toString() ?? '');
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open delivery location')),
      );
    }
  }

  Widget orderPage() => ListView(padding: const EdgeInsets.all(16), children: orders.map((raw) {
    final o = Map<String, dynamic>.from(raw);
    final next = nextStatus(o['status']);
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${o['orderNumber']} • ${o['customerName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
      Text('${o['phone']}'),
      if (o['latitude'] != null && o['longitude'] != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => openDeliveryLocation(o['latitude'], o['longitude']),
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Open delivery location'),
          ),
        )
      else
        Text(o['deliveryLocation']?.toString() ?? 'Location unavailable'),
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
        leading: imageOrPlaceholder(s['imageUrl']?.toString(), Icons.store),
        title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(s['category']),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (s['owner'] == null)
            FilledButton.tonal(onPressed: () => addAdmin(s), child: const Text('Create Admin'))
          else
            IconButton(
              tooltip: 'Update admin email/password',
              onPressed: () => editAdmin(s),
              icon: const Icon(Icons.manage_accounts_outlined),
            ),
          IconButton(
            tooltip: 'Update shop and pictures',
            onPressed: () => editShop(s),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete shop',
            onPressed: () => deleteShop(s),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ]),
      ));
    }),
  ]);

  @override
  Widget build(BuildContext context) {
    final pages = superAdmin ? [shopsPage(), orderPage()] : [productPage(), orderPage()];
    return Scaffold(
      appBar: AppBar(
        leading: page == 1
            ? IconButton(
                tooltip: superAdmin ? 'Back to shops' : 'Back to products',
                onPressed: () => setState(() => page = 0),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: Text(
          superAdmin ? 'UET Shops • Super Admin' : 'Shop Admin Dashboard',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
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
