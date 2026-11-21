import 'package:supabase_flutter/supabase_flutter.dart';

class ArtBookOrdersRepository {
  final SupabaseClient client;
  const ArtBookOrdersRepository({required this.client});

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Please sign in to view your orders.');
    return id;
  }

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final userId = _userId;
    final rows = await client
        .from('orders')
        .select('*,order_items(*),order_events(*)')
        .or('buyer_user_id.eq.$userId,artisan_user_id.eq.$userId')
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, String>> getPendingArtisanApprovals() async {
    final rows = await client
        .from('agent_approvals')
        .select('id,payload')
        .eq('owner_user_id', _userId)
        .eq('action_type', 'accept_order')
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final result = <String, String>{};
    for (final row in rows) {
      final payload = row['payload'];
      if (payload is Map && payload['order_id'] != null) {
        result[payload['order_id'].toString()] = row['id'].toString();
      }
    }
    return result;
  }
}
