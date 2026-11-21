import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class ArtisanProductRepository {
  final SupabaseClient client;

  const ArtisanProductRepository({required this.client});

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) {
      throw const AuthException('Please sign in to manage product listings.');
    }
    return id;
  }

  Future<String> _artisanProfileId() async {
    final row = await client
        .from('artisan_profiles')
        .select('id')
        .eq('user_id', _userId)
        .maybeSingle();

    if (row == null) {
      throw const AuthException('Create your artisan profile before adding products.');
    }
    return row['id'].toString();
  }

  Future<List<Map<String, dynamic>>> getCraftCategories() async {
    final rows = await client
        .from('craft_categories')
        .select('id,name,slug')
        .eq('is_active', true)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getMyProducts() async {
    final artisanId = await _artisanProfileId();
    final rows = await client
        .from('products')
        .select('*,product_media(*)')
        .eq('artisan_profile_id', artisanId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getPublishedProducts({
    String? search,
    String? categoryId,
    int limit = 30,
  }) async {
    var query = client
        .from('products')
        .select('*,product_media(*),artisan_profiles(public_name,public_slug,craft_region),craft_categories(name,slug)')
        .eq('status', 'published');

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('title', '%${search.trim()}%');
    }

    final rows = await query
        .order('published_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> createDraft({
    required String title,
    required String description,
    required String craftStory,
    required String craftOrigin,
    required String categoryId,
    required double price,
    required int availableQuantity,
    required int minimumOrderQuantity,
    double? floorPrice,
  }) async {
    final artisanId = await _artisanProfileId();
    final slugBase = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final slug = '${slugBase.isEmpty ? 'handmade-product' : slugBase}-${DateTime.now().microsecondsSinceEpoch}';

    final product = await client.from('products').insert({
      'artisan_profile_id': artisanId,
      'category_id': categoryId.isEmpty ? null : categoryId,
      'title': title.trim(),
      'slug': slug,
      'description': description.trim(),
      'craft_story': craftStory.trim(),
      'craft_origin': craftOrigin.trim(),
      'price': price,
      'currency': 'INR',
      'available_quantity': availableQuantity,
      'min_order_quantity': minimumOrderQuantity,
      'is_handmade': true,
    }).select().single();

    if (floorPrice != null) {
      await client.from('product_private_terms').insert({
        'product_id': product['id'],
        'artisan_user_id': _userId,
        'floor_price': floorPrice,
      });
    }

    return product;
  }

  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    String? altText,
    bool isPrimary = true,
  }) async {
    final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$_userId/$productId/${DateTime.now().microsecondsSinceEpoch}_$safeFileName';

    await client.storage.from('artbook-agent-intake').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );

    if (isPrimary) {
      await client
          .from('product_media')
          .update({'is_primary': false})
          .eq('product_id', productId);
    }

    await client.from('product_media').insert({
      'product_id': productId,
      'storage_path': path,
      'storage_bucket': 'artbook-agent-intake',
      'media_type': 'image',
      'alt_text': altText,
      'is_primary': isPrimary,
    });

    final signed = await client.storage
        .from('artbook-agent-intake')
        .createSignedUrl(path, 60);
    return signed;
  }
  Future<String> uploadAgentImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$_userId/intake/${DateTime.now().microsecondsSinceEpoch}_$safeFileName';

    await client.storage.from('artbook-agent-intake').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );
    return path;
  }

  Future<Map<String, dynamic>> requestListingPublication({
    required String productId,
  }) async {
    final response = await client.functions.invoke(
      'request-listing-publication',
      body: {'product_id': productId},
    );
    if (response.status < 200 || response.status >= 300) {
      final details = response.data is Map ? response.data['error'] : null;
      throw AuthException(details?.toString() ?? 'Publication request failed.');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> decideApproval({
    required String approvalId,
    required bool approve,
  }) async {
    final response = await client.functions.invoke(
      'agent-approval',
      body: {
        'approval_id': approvalId,
        'decision': approve ? 'approve' : 'reject',
      },
    );
    if (response.status < 200 || response.status >= 300) {
      final details = response.data is Map ? response.data['error'] : null;
      throw AuthException(details?.toString() ?? 'The approval could not be recorded.');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

}
