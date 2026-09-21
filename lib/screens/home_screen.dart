import 'dart:convert';
import 'dart:typed_data';
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
  String search = '';

  @override
  void initState() {
    super.initState();
    future = ApiService.shops();
  }

  Future<void> refresh() async {
    setState(() => future = ApiService.shops());
    await future;
  }

  IconData iconFor(String value) {
    final v = value.toLowerCase();
    if (v.contains('fruit')) return Icons.apple_rounded;
    if (v.contains('canteen')) return Icons.restaurant_rounded;
    if (v.contains('laundry')) return Icons.local_laundry_service_rounded;
    if (v.contains('barber')) return Icons.content_cut_rounded;
    if (v.contains('book')) return Icons.menu_book_rounded;
    if (v.contains('station')) return Icons.draw_rounded;
    return Icons.storefront_rounded;
  }

  List<Color> colorsFor(String value) {
    final v = value.toLowerCase();
    if (v.contains('fruit')) return const [Color(0xFFFF6B4A), Color(0xFFFF9A44)];
    if (v.contains('canteen')) return const [Color(0xFF7B3FF2), Color(0xFFB35CFF)];
    if (v.contains('laundry')) return const [Color(0xFF0086E6), Color(0xFF27C2F2)];
    if (v.contains('barber')) return const [Color(0xFF152C67), Color(0xFF3967C9)];
    if (v.contains('general')) return const [Color(0xFF00A779), Color(0xFF38C991)];
    return const [Color(0xFF424EF5), Color(0xFF7380FF)];
  }

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

  void openShop(Map<String, dynamic> shop) {
    if (shop['isOpen'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This shop is currently closed')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopScreen(shop: shop, user: widget.user),
      ),
    );
  }

  Widget universityHeader() {
    final firstName = (widget.user['name']?.toString().trim().split(' ').first ?? 'Student');
    return Container(
      height: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF101B5C), Color(0xFF424EF5), Color(0xFF6370FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: EngineeringPatternPainter())),
        Positioned(
          right: -45,
          top: 56,
          child: Icon(
            Icons.settings_outlined,
            size: 190,
            color: Colors.white.withValues(alpha: 0.055),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 5)),
                    ],
                  ),
                  child: Image.asset('assets/images/uet_shops_logo.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      'UET SHOPS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    Text(
                      'University of Engineering & Technology',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ]),
                ),
                IconButton.filledTonal(
                  tooltip: 'My orders',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  tooltip: 'Logout',
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    foregroundColor: Colors.white,
                  ),
                ),
              ]),
              const Spacer(),
              Text(
                'Hello, $firstName!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Everything you need, right here on campus.',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 7)),
                  ],
                ),
                child: TextField(
                  onChanged: (value) => setState(() => search = value.trim().toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Search campus shops...',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget shopCard(Map<String, dynamic> shop) {
    final category = shop['category']?.toString() ?? 'Campus Shop';
    final colors = colorsFor(category);
    final isOpen = shop['isOpen'] == true;
    final provider = imageProvider(
      shop['backgroundImageUrl']?.toString() ?? shop['imageUrl']?.toString(),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openShop(shop),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            image: provider == null
                ? null
                : DecorationImage(
                    image: provider,
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      colors.first.withValues(alpha: 0.58),
                      BlendMode.srcOver,
                    ),
                  ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(children: [
            Positioned(
              right: -12,
              bottom: -18,
              child: Icon(
                iconFor(category),
                size: 108,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                  ),
                  child: Icon(iconFor(category), color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            shop['name']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: isOpen ? const Color(0xFFCEFFE8) : const Color(0xFFFFD8D8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOpen ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              color: isOpen ? const Color(0xFF08764D) : const Color(0xFFB3261E),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      Text(category, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 9),
                      Row(children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 19),
                        const SizedBox(width: 4),
                        Text(
                          '${shop['rating'] ?? 0}  (${shop['ratingCount'] ?? 0} reviews)',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snapshot) {
          final allShops = snapshot.data ?? [];
          final shops = allShops
              .map((raw) => Map<String, dynamic>.from(raw))
              .where((shop) {
                if (search.isEmpty) return true;
                final value = '${shop['name']} ${shop['category']}'.toLowerCase();
                return value.contains(search);
              })
              .toList();
          final openCount =
              shops.where((shop) => shop['isOpen'] == true).length;

          return RefreshIndicator(
            onRefresh: refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: universityHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(children: [
                      Container(
                        width: 5,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF424EF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Explore Campus Shops',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '$openCount available',
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
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
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'Could not load shops\n${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ]),
                      ),
                    ),
                  )
                else if (shops.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('No matching campus shops found'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 500,
                        mainAxisExtent: 145,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => shopCard(shops[index]),
                        childCount: shops.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EngineeringPatternPainter extends CustomPainter {
  const EngineeringPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.16);

    final paths = [
      [Offset(0, 74), Offset(70, 74), Offset(100, 104), Offset(190, 104)],
      [Offset(size.width * .34, 0), Offset(size.width * .34, 45), Offset(size.width * .40, 75)],
      [Offset(size.width - 210, 34), Offset(size.width - 150, 34), Offset(size.width - 110, 74), Offset(size.width, 74)],
      [Offset(size.width * .58, size.height), Offset(size.width * .58, size.height - 34), Offset(size.width * .64, size.height - 64)],
    ];

    for (final points in paths) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
        canvas.drawCircle(point, 3.2, dotPaint);
      }
      canvas.drawPath(path, paint);
    }

    for (double x = 24; x < size.width; x += 88) {
      canvas.drawCircle(Offset(x, 22), 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
