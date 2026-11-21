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
    'handloom-weaving' => Icons.texture,
    'pottery-ceramics' => Icons.brush,
    'woodcraft' => Icons.carpenter_outlined,
    'metalcraft' => Icons.hardware_outlined,
    'folk-tribal-art' => Icons.palette_outlined,
    'natural-fibre-basketry' => Icons.grass_outlined,
    'embroidery-needlework' => Icons.auto_awesome,
    'jewellery-accessories' => Icons.diamond_outlined,
    _ => Icons.category_outlined,
  };

  void _openCategory(Map<String, dynamic> category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtBookMarketplacePage(
          initialCategoryId: category['id'].toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
      appBar: AppBar(
        title: const Text('Explore Crafts'),
        backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.23,
                    ),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final slug = category['slug']?.toString() ?? '';
                      return Material(
                        color: isDark ? AppColors.neutral800 : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _openCategory(category),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? AppColors.neutral700 : const Color(0xFFEDE4D9),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFE9D8C5),
                                  child: Icon(
                                    _iconFor(slug),
                                    color: const Color(0xFF6F3E2B),
                                  ),
                                ),
                                Text(
                                  category['name']?.toString() ?? 'Craft category',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Row(
                                  children: [
                                    Text(
                                      'Explore creations',
                                      style: TextStyle(
                                        color: Color(0xFF8B735F),
                                        fontSize: 11,
                                      ),
                                    ),
                                    Spacer(),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Color(0xFF8B735F),
                                      size: 17,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
