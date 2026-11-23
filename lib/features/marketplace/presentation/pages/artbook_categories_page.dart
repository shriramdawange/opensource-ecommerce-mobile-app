import 'package:flutter/material.dart';

import '../../../../core/supabase/artbook_supabase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../artisan/data/repositories/artisan_product_repository.dart';
import 'artbook_marketplace_page.dart';

class ArtBookCategoriesPage extends StatefulWidget {
  const ArtBookCategoriesPage({super.key});

  @override
  State<ArtBookCategoriesPage> createState() => _ArtBookCategoriesPageState();
}

class _ArtBookCategoriesPageState extends State<ArtBookCategoriesPage> {
  late final ArtisanProductRepository _repository;
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;

  static const _paper = Color(0xFFFAF7F1);
  static const _clay = Color(0xFF9A4F36);
  static const _ink = Color(0xFF28251F);
  static const _muted = Color(0xFF81796E);

  @override
  void initState() {
    super.initState();
    _repository = ArtisanProductRepository(client: ArtBookSupabase.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories = await _repository.getCraftCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconFor(String slug) => switch (slug) {
    'handloom-weaving' => Icons.texture_rounded,
    'pottery-ceramics' => Icons.ramen_dining_rounded,
    'woodcraft' => Icons.carpenter_rounded,
    'metalcraft' => Icons.hardware_rounded,
    'folk-tribal-art' => Icons.palette_rounded,
    'natural-fibre-basketry' => Icons.grass_rounded,
    'embroidery-needlework' => Icons.auto_awesome_rounded,
    'jewellery-accessories' => Icons.diamond_rounded,
    _ => Icons.category_rounded,
  };

  void _openCategory(Map<String, dynamic> category) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ArtBookMarketplacePage(initialCategoryId: category['id'].toString()),
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
      appBar: AppBar(
        title: Text('Explore crafts', style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 19)),
        backgroundColor: background,
        actions: [IconButton(onPressed: _load, tooltip: 'Refresh', icon: Icon(Icons.refresh_rounded, color: text))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _clay))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, size: 42, color: _clay), const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _load, style: FilledButton.styleFrom(backgroundColor: _clay), child: const Text('Try again'))])))
              : RefreshIndicator(
                  color: _clay,
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: const LinearGradient(colors: [Color(0xFF633B2D), Color(0xFFAD6747)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            ),
                            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('ROOTED IN CULTURE', style: TextStyle(color: Color(0xFFFFDCC4), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.8)),
                              SizedBox(height: 10),
                              Text('Explore the art\nof making.', style: TextStyle(color: Colors.white, fontSize: 29, height: 1.08, fontWeight: FontWeight.w900)),
                              SizedBox(height: 9),
                              Text('From timeless handlooms to expressive folk art, find work made with meaning.', style: TextStyle(color: Color(0xFFF5E6DA), height: 1.4, fontSize: 12)),
                            ]),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('FIND YOUR FAVOURITE', style: TextStyle(color: _clay, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
                            const SizedBox(height: 5),
                            Text('Craft categories', style: TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w900)),
                          ]),
                        ),
                      ),
                      if (_categories.isEmpty)
                        const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('Craft categories will appear here.')))
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate((context, index) {
                              final category = _categories[index];
                              final slug = category['slug']?.toString() ?? '';
                              final name = category['name']?.toString() ?? 'Craft category';
                              final colors = [const Color(0xFFEAD8C8), const Color(0xFFE4E6D8), const Color(0xFFF0E1CE), const Color(0xFFE8DDE8)];
                              final tint = colors[index % colors.length];
                              return Material(
                                color: card,
                                borderRadius: BorderRadius.circular(21),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => _openCategory(category),
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Container(width: 52, height: 52, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(17)), child: Icon(_iconFor(slug), color: _clay, size: 25)),
                                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: text, fontSize: 14, height: 1.2, fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 8),
                                        const Row(children: [Text('Explore collection', style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w600)), Spacer(), Icon(Icons.arrow_outward_rounded, size: 15, color: _clay)]),
                                      ]),
                                    ]),
                                  ),
                                ),
                              );
                            }, childCount: _categories.length),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.12),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
