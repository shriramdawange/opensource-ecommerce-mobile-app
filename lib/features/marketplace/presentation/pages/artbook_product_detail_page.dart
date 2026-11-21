import 'package:flutter/material.dart';

import '../../../../core/supabase/artbook_supabase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../commerce/data/repositories/artbook_cart_repository.dart';

class ArtBookProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  const ArtBookProductDetailPage({super.key, required this.product});

  @override
  State<ArtBookProductDetailPage> createState() => _ArtBookProductDetailPageState();
}

class _ArtBookProductDetailPageState extends State<ArtBookProductDetailPage> {
  int _quantity = 1;
  bool _adding = false;

  String? get _imageUrl {
    final media = widget.product['product_media'];
    if (media is! List || media.isEmpty) return null;
    final row = media.firstWhere(
      (item) => item is Map && item['is_primary'] == true,
      orElse: () => media.first,
    );
    if (row is! Map || row['storage_path'] == null) return null;
    return ArtBookSupabase.client.storage
        .from('artbook-product-media')
        .getPublicUrl(row['storage_path'].toString());
  }

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    try {
      await ArtBookCartRepository(client: ArtBookSupabase.client).addItem(
        productId: widget.product['id'].toString(),
        quantity: _quantity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to your ArtBook cart.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final artisan = product['artisan_profiles'] is Map
        ? Map<String, dynamic>.from(product['artisan_profiles'] as Map)
        : <String, dynamic>{};
    final category = product['craft_categories'] is Map
        ? Map<String, dynamic>.from(product['craft_categories'] as Map)
        : <String, dynamic>{};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final available = (product['available_quantity'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
      appBar: AppBar(
        title: const Text('ArtBook'),
        backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: FilledButton.icon(
            onPressed: _adding || available < 1 ? null : _addToCart,
            icon: _adding
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.shopping_bag_outlined),
            label: Text(_adding ? 'Adding…' : 'Add to cart'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6F3E2B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1,
              child: _imageUrl == null
                  ? Container(
                      color: const Color(0xFFF1E7DA),
                      child: const Icon(Icons.image_outlined, size: 64, color: Color(0xFF96765B)),
                    )
                  : Image.network(
                      _imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, size: 52),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            category['name']?.toString() ?? 'Handmade creation',
            style: const TextStyle(color: Color(0xFF9A6A40), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            product['title']?.toString() ?? 'Untitled creation',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.1),
          ),
          const SizedBox(height: 8),
          Text(
            '₹\${product['price'] ?? '—'}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF6F3E2B)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: Color(0xFF8B735F)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  artisan['public_name']?.toString() ?? 'Independent artisan',
                  style: const TextStyle(color: Color(0xFF8B735F)),
                ),
              ),
              Text(
                available > 0 ? '$available available' : 'Unavailable',
                style: TextStyle(
                  color: available > 0 ? const Color(0xFF37734A) : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if ((artisan['craft_region'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Craft region: \${artisan['craft_region']}',
              style: const TextStyle(color: Color(0xFF8B735F), fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          _section('About this creation', product['description']?.toString()),
          _section('Story behind the craft', product['craft_story']?.toString()),
          _section('Origin', product['craft_origin']?.toString()),
          if (product['materials'] is List && (product['materials'] as List).isNotEmpty)
            _section('Materials', (product['materials'] as List).join(', ')),
          if (product['techniques'] is List && (product['techniques'] as List).isNotEmpty)
            _section('Techniques', (product['techniques'] as List).join(', ')),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w700))),
              IconButton(
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.w800)),
              IconButton(
                onPressed: _quantity < available ? () => setState(() => _quantity++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(height: 1.45, color: Color(0xFF6F6258))),
        ],
      ),
    );
  }
}
