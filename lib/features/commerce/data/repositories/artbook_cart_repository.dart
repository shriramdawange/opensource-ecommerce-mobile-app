import 'package:supabase_flutter/supabase_flutter.dart';

class ArtBookCartRepository {
  final SupabaseClient client;
  const ArtBookCartRepository({required this.client});

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Please sign in to use your cart.');
    return id;
  }

  Future<String> _getOrCreateCartId() async {
    final userId = _userId;
    final existing = await client.from('carts').select('id')
        .eq('buyer_user_id', userId).maybeSingle();
    if (existing != null) return existing['id'].toString();
    final created = await client.from('carts')
        .insert({'buyer_user_id': userId, 'currency': 'INR'})
        .select('id').single();
    return created['id'].toString();
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final cartId = await _getOrCreateCartId();
    final rows = await client.from('cart_items')
        .select('id,quantity,product_id,products(id,title,price,currency,available_quantity,status,product_media(storage_path,is_primary))')
        .eq('cart_id', cartId).order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addItem({required String productId, int quantity = 1}) async {
    if (quantity < 1) throw const AuthException('Quantity must be at least one.');
    final product = await client.from('products')
        .select('id,status,available_quantity').eq('id', productId).maybeSingle();
    if (product == null || product['status'] != 'published') {
      throw const AuthException('This product is not available for purchase.');
    }
    final available = (product['available_quantity'] as num?)?.toInt() ?? 0;
    if (quantity > available) {
      throw const AuthException('The requested quantity is not currently available.');
    }

    final cartId = await _getOrCreateCartId();
    final existing = await client.from('cart_items').select('id,quantity')
        .eq('cart_id', cartId).eq('product_id', productId).maybeSingle();
    if (existing == null) {
      await client.from('cart_items').insert({
        'cart_id': cartId, 'product_id': productId, 'quantity': quantity,
      });
    } else {
      final nextQuantity = (existing['quantity'] as num).toInt() + quantity;
      if (nextQuantity > available) {
        throw const AuthException('The requested quantity exceeds available stock.');
      }
      await client.from('cart_items').update({'quantity': nextQuantity})
          .eq('id', existing['id'].toString());
    }
  }

  Future<void> setQuantity({required String cartItemId, required int quantity}) async {
    if (quantity < 1) return removeItem(cartItemId: cartItemId);
    await client.from('cart_items').update({'quantity': quantity}).eq('id', cartItemId);
  }

  Future<void> removeItem({required String cartItemId}) async {
    await client.from('cart_items').delete().eq('id', cartItemId);
  }

  /// Order creation is server-only: server re-reads prices and stock and
  /// creates a pending artisan approval. This call does not capture payment.
  Future<Map<String, dynamic>> requestOrder({
    required Map<String, dynamic> shippingAddress,
    required String idempotencyKey,
    required bool buyerConfirmed,
  }) async {
    if (!buyerConfirmed) {
      throw const AuthException(
        'Confirm the order and shipping-address sharing before continuing.',
      );
    }
    final cartId = await _getOrCreateCartId();
    final response = await client.functions.invoke('place-order', body: {
      'cart_id': cartId,
      'shipping_address': shippingAddress,
      'idempotency_key': idempotencyKey,
      'buyer_confirmed': true,
    });
    if (response.status < 200 || response.status >= 300) {
      throw AuthException('Order request failed (\${response.status}).');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }
}
