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

  static const _clay = Color(0xFFEA1A34);
  static const _paper = Color(0xFFF9F9FB);
  static const _ink = Color(0xFF25232A);
  static const _muted = Color(0xFF77727A);

  String? get _imageUrl {
    final media = widget.product['product_media'];
    if (media is! List || media.isEmpty) return null;
    final row = media.firstWhere((item) => item is Map && item['is_primary'] == true, orElse: () => media.first);
    if (row is! Map || row['storage_path'] == null) return null;
    final bucket = row['storage_bucket']?.toString() ?? 'artbook-product-media';
    return ArtBookSupabase.client.storage.from(bucket).getPublicUrl(row['storage_path'].toString());
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
        const SnackBar(content: Text('Added to your DARSH cart.'), behavior: SnackBarBehavior.floating),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final artisan = product['artisan_profiles'] is Map ? Map<String, dynamic>.from(product['artisan_profiles'] as Map) : <String, dynamic>{};
    final category = product['craft_categories'] is Map ? Map<String, dynamic>.from(product['craft_categories'] as Map) : <String, dynamic>{};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.neutral900 : _paper;
    final card = isDark ? AppColors.neutral800 : Colors.white;
    final text = isDark ? Colors.white : _ink;
    final available = (product['available_quantity'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: Text('The story behind it', style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: Icon(Icons.close_rounded, color: text))],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          decoration: BoxDecoration(color: card, border: Border(top: BorderSide(color: isDark ? AppColors.neutral700 : const Color(0xFFF1F0F2)))),
          child: Row(children: [
            Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TOTAL PRICE', style: TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 3),
              Text('₹${((double.tryParse(product['price']?.toString() ?? '') ?? 0) * _quantity).toStringAsFixed(0)}', style: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w900)),
            ])),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: FilledButton.icon(
              onPressed: _adding || available < 1 ? null : _addToCart,
              icon: _adding ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.shopping_bag_outlined, size: 18),
              label: Text(_adding ? 'Adding…' : available < 1 ? 'Out of stock' : 'Add to bag'),
              style: FilledButton.styleFrom(backgroundColor: _clay, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            )),
          ]),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: AspectRatio(
              aspectRatio: .94,
              child: Stack(fit: StackFit.expand, children: [
                Container(color: const Color(0xFFEDE4D8), child: _imageUrl == null ? const Center(child: Icon(Icons.image_outlined, size: 64, color: Color(0xFF9A806A))) : Image.network(_imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 48)))),
                Positioned(left: 14, bottom: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(30)), child: const Row(children: [Icon(Icons.verified_outlined, color: _clay, size: 14), SizedBox(width: 5), Text('MADE BY AN ARTISAN', style: TextStyle(color: _ink, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .7))]))),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Text((category['name']?.toString() ?? 'HANDMADE').toUpperCase(), style: const TextStyle(color: _clay, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
          const SizedBox(height: 7),
          Text(product['title']?.toString() ?? 'Untitled creation', style: TextStyle(color: text, fontSize: 27, height: 1.12, fontWeight: FontWeight.w900, letterSpacing: -.6)),
          const SizedBox(height: 9),
          Text('₹${product['price'] ?? '—'}', style: const TextStyle(color: _clay, fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? AppColors.neutral700 : const Color(0xFFF1F0F2))),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEAD8C8), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.person_outline_rounded, color: _clay)),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CREATED BY', style: TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 3),
                Text(artisan['public_name']?.toString() ?? 'Independent artisan', style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 13)),
                if ((artisan['craft_region'] ?? '').toString().isNotEmpty) Text(artisan['craft_region'].toString(), style: const TextStyle(color: _muted, fontSize: 11)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: available > 0 ? const Color(0xFFE7F0E5) : const Color(0xFFFCE9E5), borderRadius: BorderRadius.circular(20)), child: Text(available > 0 ? 'In stock' : 'Sold out', style: TextStyle(color: available > 0 ? const Color(0xFF386447) : Colors.red, fontSize: 10, fontWeight: FontWeight.w800))),
            ]),
          ),
          const SizedBox(height: 18),
          _storySection('The creation', 'About this creation', product['description']?.toString(), card, text),
          _storySection('THE MAKER’S STORY', 'Story behind the craft', product['craft_story']?.toString(), card, text),
          _storySection('PLACE & PROCESS', 'Origin', product['craft_origin']?.toString(), card, text),
          if (product['materials'] is List && (product['materials'] as List).isNotEmpty) _storySection('MATERIALS', 'What it is made from', (product['materials'] as List).join(', '), card, text),
          if (product['techniques'] is List && (product['techniques'] as List).isNotEmpty) _storySection('TECHNIQUE', 'How it is made', (product['techniques'] as List).join(', '), card, text),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? AppColors.neutral700 : const Color(0xFFF1F0F2))),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Choose quantity', style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 13)), const SizedBox(height: 3), const Text('Each piece supports a maker.', style: TextStyle(color: _muted, fontSize: 10))])),
              IconButton(onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null, icon: const Icon(Icons.remove_circle_outline_rounded, color: _clay)),
              Text('$_quantity', style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w900)),
              IconButton(onPressed: _quantity < available ? () => setState(() => _quantity++) : null, icon: const Icon(Icons.add_circle_outline_rounded, color: _clay)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _storySection(String eyebrow, String title, String? value, Color card, Color text) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eyebrow.toUpperCase(), style: const TextStyle(color: _clay, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(value, style: const TextStyle(color: _muted, fontSize: 12, height: 1.55)),
        ]),
      ),
    );
  }
}
