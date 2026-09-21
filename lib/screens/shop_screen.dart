import 'dart:convert';
import 'dart:typed_data';
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

  ImageProvider? imageProvider(String? value) {
    final source = value?.trim() ?? '';
    if (source.isEmpty) return null;
    if (source.startsWith('data:image')) {
      try {
        final Uint8List bytes = base64Decode(source.split(',').last);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(source);
  }

  IconData get shopIcon {
    final category = widget.shop['category']?.toString().toLowerCase() ?? '';
    if (category.contains('fruit')) return Icons.apple_rounded;
    if (category.contains('canteen')) return Icons.restaurant_rounded;
    if (category.contains('laundry')) return Icons.local_laundry_service_rounded;
    if (category.contains('barber')) return Icons.content_cut_rounded;
    return Icons.storefront_rounded;
  }

  Future<void> refresh() async {
    setState(() => future = ApiService.products(widget.shop['_id']));
    await future;
  }

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
      throw Exception(
        'Location permission is blocked. Enable it from app/browser settings',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<void> checkout(List<dynamic> products) async {
    if (placingOrder) return;
    setState(() => placingOrder = true);
    try {
      final position = await currentPosition();
      await ApiService.placeOrder({
        'shop': widget.shop['_id'],
        'items': products
            .where((p) => quantity(p['_id']) > 0)
            .map(
              (p) => {
                'product': p['_id'],
                'quantity': quantity(p['_id']),
              },
            )
            .toList(),
        'phone': widget.user['phone'],
        'deliveryLocation': 'GPS location',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'notes': '',
      });
      if (!mounted) return;
      setState(cart.clear);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order sent to shop admin successfully'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => placingOrder = false);
    }
  }

  Widget shopHeader() {
    final background = imageProvider(
      widget.shop['backgroundImageUrl']?.toString() ??
          widget.shop['imageUrl']?.toString(),
    );
    return Container(
      height: 255,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111D62), Color(0xFF424EF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: background == null
            ? null
            : DecorationImage(
                image: background,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  const Color(0xFF101B5C).withValues(alpha: 0.65),
                  BlendMode.srcOver,
                ),
              ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Stack(children: [
        Positioned(
          right: -24,
          bottom: -30,
          child: Icon(
            shopIcon,
            size: 190,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Positioned(
          right: 70,
          top: 48,
          child: Icon(
            Icons.settings_outlined,
            size: 70,
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton.filledTonal(
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.17),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCEFFE8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(children: [
                      Icon(
                        Icons.circle,
                        size: 9,
                        color: Color(0xFF0A8F5C),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'OPEN NOW',
                        style: TextStyle(
                          color: Color(0xFF08764D),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                    ]),
                  ),
                ]),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Icon(shopIcon, color: Colors.white, size: 38),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.shop['name']?.toString() ?? 'Campus Shop',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.shop['description']?.toString() ??
                                'Serving the UET campus community',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 17,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'UET Campus  •  ★ ${widget.shop['rating'] ?? 0}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget quantityControl(String id) {
    final qty = quantity(id);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EBFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFCCD2FF)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 34,
          height: 34,
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Decrease quantity',
            onPressed: qty == 0
                ? null
                : () => setState(() {
                    if (qty == 1) {
                      cart.remove(id);
                    } else {
                      cart[id] = qty - 1;
                    }
                  }),
            icon: Icon(
              Icons.remove_rounded,
              size: 20,
              color: qty == 0 ? Colors.grey.shade400 : const Color(0xFF424EF5),
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 30),
          alignment: Alignment.center,
          child: Text(
            '$qty',
            style: const TextStyle(
              color: Color(0xFF17216A),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(
          width: 34,
          height: 34,
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Increase quantity',
            onPressed: () => setState(() => cart[id] = qty + 1),
            icon: const Icon(
              Icons.add_rounded,
              size: 20,
              color: Color(0xFF424EF5),
            ),
          ),
        ),
      ]),
    );
  }

  Widget productCard(Map<String, dynamic> product) {
    final id = product['_id'] as String;
    final available = product['isAvailable'] == true;
    final provider = imageProvider(product['imageUrl']?.toString());
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6E9F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F1F5B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(children: [
        Container(
          width: 125,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EBFF),
            image: provider == null
                ? null
                : DecorationImage(image: provider, fit: BoxFit.cover),
          ),
          child: provider == null
              ? const Icon(
                  Icons.fastfood_rounded,
                  size: 46,
                  color: Color(0xFF424EF5),
                )
              : null,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      product['name']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (!available)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'SOLD OUT',
                        style: TextStyle(
                          color: Color(0xFFB3261E),
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 5),
                Text(
                  product['description']?.toString().trim().isNotEmpty == true
                      ? product['description'].toString()
                      : 'Freshly available on UET campus',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                Row(children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: 'Rs. ${product['price']}',
                          style: const TextStyle(
                            color: Color(0xFF424EF5),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${product['unit']}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ]),
                    ),
                  ),
                  if (available) quantityControl(id),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget cartBar(List<dynamic> products, int count, double total) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        padding: const EdgeInsets.fromLTRB(16, 11, 11, 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF121E64), Color(0xFF424EF5)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x50424EF5),
              blurRadius: 20,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(alignment: Alignment.center, children: [
              const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
              ),
              Positioned(
                right: 4,
                top: 3,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC928),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count item${count == 1 ? '' : 's'} selected',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Rs. ${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: placingOrder || count == 0 ? null : () => checkout(products),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2837D8),
              disabledBackgroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            ),
            icon: placingOrder
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.near_me_rounded),
            label: Text(
              placingOrder
                  ? 'Locating...'
                  : count == 0
                      ? 'Add Items'
                      : 'Place Order',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final count = cart.values.fold<int>(0, (a, b) => a + b);
        final total = products.fold<double>(
          0,
          (sum, product) =>
              sum +
              ((product['price'] as num?)?.toDouble() ?? 0) *
                  quantity(product['_id']),
        );

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: shopHeader()),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(children: [
                      Icon(
                        Icons.grid_view_rounded,
                        color: Color(0xFF424EF5),
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Available Menu',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ]),
                  ),
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: FilledButton.icon(
                        onPressed: refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Could not load menu — Try again'),
                      ),
                    ),
                  )
                else if (products.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('No products available yet'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      4,
                      20,
                      105,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 560,
                        mainAxisExtent: 155,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => productCard(
                          Map<String, dynamic>.from(products[index]),
                        ),
                        childCount: products.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: cartBar(products, count, total),
        );
      },
    );
  }
}
