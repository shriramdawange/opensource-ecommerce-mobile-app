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

  Future<void> _search() => _load();

  String? _primaryImage(Map<String, dynamic> product) {
    final media = product['product_media'];
    if (media is! List || media.isEmpty) return null;
    final ordered = [...media]..sort((a, b) {
      final aPrimary = a is Map && a['is_primary'] == true ? 0 : 1;
      final bPrimary = b is Map && b['is_primary'] == true ? 0 : 1;
      return aPrimary.compareTo(bPrimary);
    });
    final first = ordered.first;
    if (first is! Map || first['storage_path'] == null) return null;
    final bucket = first['storage_bucket']?.toString() ?? 'artbook-product-media';
    return ArtBookSupabase.client.storage
        .from(bucket)
        .getPublicUrl(first['storage_path'].toString());
  }

  void _openProduct(Map<String, dynamic> product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtBookProductDetailPage(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B3F27),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ARTBOOK',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              'Stories made by hand',
                              style: TextStyle(fontSize: 11, color: Color(0xFF8B735F)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh marketplace',
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B2B20),
                      borderRadius: BorderRadius.circular(22),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/splash.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Made by hands.\nCarrying a story.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 9),
                        Text(
                          'Discover original crafts and meet the makers behind them.',
                          style: TextStyle(color: Color(0xFFF2E6D9), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Search crafts, materials or makers',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        onPressed: _search,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.neutral800 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              if (_categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _categoryChip('All crafts', null),
                        ..._categories.map((category) => _categoryChip(
                          category['name'].toString(),
                          category['id'].toString(),
                        )),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Discover handmade',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '\${_products.length} items',
                        style: const TextStyle(color: Color(0xFF8B735F), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Marketplace unavailable',
                    message: _error!,
                    action: 'Try again',
                    onPressed: _load,
                  ),
                )
              else if (_products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyState(
                    icon: Icons.storefront_outlined,
                    title: 'The marketplace is taking shape',
                    message: 'Published artisan products will appear here. Draft listings stay private until the maker approves publication.',
                    action: 'Refresh',
                    onPressed: _load,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = _products[index];
                        final imageUrl = _primaryImage(product);
                        final artisan = product['artisan_profiles'] is Map
                            ? Map<String, dynamic>.from(product['artisan_profiles'] as Map)
                            : <String, dynamic>{};
                        final category = product['craft_categories'] is Map
                            ? Map<String, dynamic>.from(product['craft_categories'] as Map)
                            : <String, dynamic>{};
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _openProduct(product),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.neutral800 : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? AppColors.neutral700 : const Color(0xFFEDE4D9),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    color: const Color(0xFFF1E7DA),
                                    child: imageUrl == null
                                        ? const Icon(Icons.image_outlined, size: 42, color: Color(0xFF96765B))
                                        : Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category['name']?.toString() ?? 'Handmade',
                                        style: const TextStyle(
                                          color: Color(0xFF9A6A40),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product['title']?.toString() ?? 'Handmade creation',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        artisan['public_name']?.toString() ?? 'Artisan',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Color(0xFF8B735F), fontSize: 10),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '₹\${product['price'] ?? '—'}',
                                        style: const TextStyle(
                                          color: Color(0xFF6F3E2B),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _products.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 13,
                      crossAxisSpacing: 13,
                      childAspectRatio: 0.66,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String label, String? id) {
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
        selectedColor: const Color(0xFFE9D8C5),
        labelStyle: TextStyle(
          fontSize: 12,
          color: selected ? const Color(0xFF542F20) : null,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    required String action,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF9A806A)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8B735F))),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
      ),
    );
  }
}
