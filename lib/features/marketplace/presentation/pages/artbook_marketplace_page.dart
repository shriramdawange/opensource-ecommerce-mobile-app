import 'package:flutter/material.dart';

import '../../../../core/supabase/artbook_supabase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../artisan/data/repositories/artisan_product_repository.dart';
import 'artbook_product_detail_page.dart';

class ArtBookMarketplacePage extends StatefulWidget {
  final String? initialCategoryId;
  const ArtBookMarketplacePage({super.key, this.initialCategoryId});

  @override
  State<ArtBookMarketplacePage> createState() => _ArtBookMarketplacePageState();
}

class _ArtBookMarketplacePageState extends State<ArtBookMarketplacePage> {
  late final ArtisanProductRepository _repository;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  bool _loading = true;
  String? _error;

  static const _ink = Color(0xFF28251F);
  static const _muted = Color(0xFF81796E);
  static const _paper = Color(0xFFFAF7F1);
  static const _clay = Color(0xFF9A4F36);
  static const _line = Color(0xFFECE5DA);

  @override
  void initState() {
    super.initState();
    _repository = ArtisanProductRepository(client: ArtBookSupabase.client);
    _selectedCategory = widget.initialCategoryId;
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getCraftCategories(),
        _repository.getPublishedProducts(
          search: _searchController.text.trim(),
          categoryId: _selectedCategory,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<Map<String, dynamic>>;
        _products = results[1] as List<Map<String, dynamic>>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _primaryImage(Map<String, dynamic> product) {
    final media = product['product_media'];
    if (media is! List || media.isEmpty) return null;
    final ordered = [...media]..sort((a, b) {
      final ap = a is Map && a['is_primary'] == true ? 0 : 1;
      final bp = b is Map && b['is_primary'] == true ? 0 : 1;
      return ap.compareTo(bp);
    });
    final first = ordered.first;
    if (first is! Map || first['storage_path'] == null) return null;
    final bucket = first['storage_bucket']?.toString() ?? 'artbook-product-media';
    return ArtBookSupabase.client.storage.from(bucket).getPublicUrl(first['storage_path'].toString());
  }

  void _openProduct(Map<String, dynamic> product) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ArtBookProductDetailPage(product: product),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.neutral900 : _paper;
    final card = isDark ? AppColors.neutral800 : Colors.white;
    final text = isDark ? Colors.white : _ink;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _clay,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _clay,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ARTBOOK', style: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2.1)),
                            const SizedBox(height: 2),
                            const Text('A marketplace of makers & meaning', style: TextStyle(color: _muted, fontSize: 11, letterSpacing: .15)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: _load,
                        icon: Icon(Icons.refresh_rounded, color: text),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 194),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF633B2D), Color(0xFF9A4F36), Color(0xFFC17A50)],
                      ),
                      boxShadow: [BoxShadow(color: _clay.withValues(alpha: .20), blurRadius: 22, offset: const Offset(0, 10))],
                    ),
                    child: Stack(
                      children: [
                        Positioned(right: -18, bottom: -32, child: Icon(Icons.spa_outlined, size: 190, color: Colors.white.withValues(alpha: .08))),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 23, 22, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(30)),
                                child: const Text('MADE SLOW. TREASURED FOREVER.', style: TextStyle(color: Color(0xFFFFE8D5), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                              ),
                              const SizedBox(height: 15),
                              const Text('Every craft has\na story.', style: TextStyle(color: Colors.white, fontSize: 31, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: -.7)),
                              const SizedBox(height: 9),
                              const Text('Meet the makers. Discover the hands, heritage and heart behind every creation.', style: TextStyle(color: Color(0xFFF4E5D9), fontSize: 12, height: 1.45)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: isDark ? AppColors.neutral700 : _line),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0 : .035), blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _load(),
                      style: TextStyle(color: text, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search crafts, materials or makers',
                        hintStyle: const TextStyle(color: _muted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: _clay),
                        suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.arrow_forward_rounded, color: _clay)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 17),
                      ),
                    ),
                  ),
                ),
              ),
              if (_categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 43,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _categoryChip('All crafts', null, isDark),
                        ..._categories.map((category) => _categoryChip(category['name'].toString(), category['id'].toString(), isDark)),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 23, 20, 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('THE COLLECTION', style: TextStyle(color: _clay, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.7)),
                            const SizedBox(height: 5),
                            Text('Discover handmade', style: TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -.45)),
                          ],
                        ),
                      ),
                      Text('${_products.length} pieces', style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(color: _clay)))
              else if (_error != null)
                SliverFillRemaining(hasScrollBody: false, child: _emptyState(icon: Icons.cloud_off_outlined, title: 'We could not load the collection', message: _error!, action: 'Try again', onPressed: _load, isDark: isDark))
              else if (_products.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _emptyState(icon: Icons.storefront_outlined, title: 'A little more craft is on its way', message: 'Published artisan creations will appear here. Refresh to check for new work.', action: 'Refresh collection', onPressed: _load, isDark: isDark))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = _products[index];
                      final imageUrl = _primaryImage(product);
                      final artisan = product['artisan_profiles'] is Map ? Map<String, dynamic>.from(product['artisan_profiles'] as Map) : <String, dynamic>{};
                      final category = product['craft_categories'] is Map ? Map<String, dynamic>.from(product['craft_categories'] as Map) : <String, dynamic>{};
                      return _ProductTile(
                        imageUrl: imageUrl,
                        category: category['name']?.toString() ?? 'HANDMADE',
                        title: product['title']?.toString() ?? 'Handmade creation',
                        artisan: artisan['public_name']?.toString() ?? 'Independent artisan',
                        price: product['price']?.toString() ?? '—',
                        isDark: isDark,
                        onTap: () => _openProduct(product),
                      );
                    }, childCount: _products.length),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 12,
                      childAspectRatio: .66,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String label, String? id, bool isDark) {
    final selected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _selectedCategory = id);
          _load();
        },
        showCheckmark: false,
        selectedColor: _clay,
        backgroundColor: isDark ? AppColors.neutral800 : Colors.white,
        side: BorderSide(color: selected ? _clay : (isDark ? AppColors.neutral700 : _line)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        labelStyle: TextStyle(fontSize: 11, color: selected ? Colors.white : (isDark ? Colors.white70 : _ink), fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String title, required String message, required String action, required VoidCallback onPressed, required bool isDark}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 76, height: 76, decoration: BoxDecoration(color: _clay.withValues(alpha: .10), shape: BoxShape.circle), child: Icon(icon, size: 34, color: _clay)),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white : _ink, fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, height: 1.45, fontSize: 12)),
            const SizedBox(height: 18),
            FilledButton(onPressed: onPressed, style: FilledButton.styleFrom(backgroundColor: _clay, foregroundColor: Colors.white), child: Text(action)),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final String? imageUrl;
  final String category;
  final String title;
  final String artisan;
  final String price;
  final bool isDark;
  final VoidCallback onTap;

  const _ProductTile({required this.imageUrl, required this.category, required this.title, required this.artisan, required this.price, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? Colors.white : const Color(0xFF28251F);
    return Material(
      color: isDark ? AppColors.neutral800 : Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFFEDE4D8),
                    child: imageUrl == null
                        ? const Center(child: Icon(Icons.image_outlined, size: 42, color: Color(0xFF9A806A)))
                        : Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF9A806A)))),
                  ),
                  Positioned(top: 10, left: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .93), borderRadius: BorderRadius.circular(20)), child: Text(category.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF704331), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .5)))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 11, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: text, fontSize: 13, height: 1.25, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Row(children: [const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF9A806A)), const SizedBox(width: 4), Expanded(child: Text(artisan, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF8B8176), fontSize: 10)))]),
                  const SizedBox(height: 9),
                  Text('₹$price', style: const TextStyle(color: Color(0xFF914A34), fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
