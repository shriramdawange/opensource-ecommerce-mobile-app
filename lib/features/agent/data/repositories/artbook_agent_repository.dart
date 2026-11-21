import 'package:supabase_flutter/supabase_flutter.dart';

class ArtBookAgentRepository {
  final SupabaseClient client;
  const ArtBookAgentRepository({required this.client});

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Please sign in to use ArtBook AI.');
    return id;
  }

  Future<Map<String, dynamic>> startListing({
    required String language,
    required String voiceTranscript,
    required List<String> mediaPaths,
    String? artisanNotes,
    String? idempotencyKey,
  }) async {
    _userId;
    final response = await client.functions.invoke('artbook-agent', body: {
      'action': 'start_listing',
      'input': {
        'language': language,
        'voice_transcript': voiceTranscript,
        'media_paths': mediaPaths,
        'artisan_notes': artisanNotes ?? '',
      },
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
    });
    if (response.status < 200 || response.status >= 300) {
      final details = response.data is Map ? response.data['error'] : null;
      throw AuthException(details?.toString() ?? 'ArtBook AI request failed.');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getCase(String caseId) async {
    _userId;
    final row = await client.from('agent_cases').select('*,agent_case_steps(*)')
        .eq('id', caseId).single();
    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> getPriceGuidance({required String productId}) async {
    _userId;
    final response = await client.functions.invoke('price-guidance', body: {
      'product_id': productId,
    });
    if (response.status < 200 || response.status >= 300) {
      throw const AuthException('Price guidance could not be generated.');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> matchBuyers({required String productId}) async {
    _userId;
    final response = await client.functions.invoke('buyer-matching', body: {
      'product_id': productId,
    });
    if (response.status < 200 || response.status >= 300) {
      throw const AuthException('Buyer matching is temporarily unavailable.');
    }
    final data = response.data as Map;
    final matches = data['matches'] as List? ?? const [];
    return matches.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }


  Future<Map<String, dynamic>> saveListingDraft({
    required String caseId,
    required String title,
    required String description,
    required String craftStory,
    required String craftOrigin,
    required String categoryId,
    required double price,
    double? floorPrice,
    required int availableQuantity,
    required int minimumOrderQuantity,
    List<String> materials = const [],
    List<String> techniques = const [],
    List<String> mediaPaths = const [],
  }) async {
    _userId;
    final response = await client.functions.invoke('save-listing-draft', body: {
      'case_id': caseId,
      'title': title,
      'description': description,
      'craft_story': craftStory,
      'craft_origin': craftOrigin,
      'category_id': categoryId,
      'price': price,
      'floor_price': floorPrice,
      'available_quantity': availableQuantity,
      'min_order_quantity': minimumOrderQuantity,
      'materials': materials,
      'techniques': techniques,
      'media_paths': mediaPaths,
    });
    if (response.status < 200 || response.status >= 300) {
      final details = response.data is Map ? response.data['error'] : null;
      throw AuthException(details?.toString() ?? 'The listing draft could not be saved.');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> requestListingPublication({
    required String productId,
  }) async {
    _userId;
    final response = await client.functions.invoke('request-listing-publication', body: {
      'product_id': productId,
    });
    if (response.status < 200 || response.status >= 300) {
      final details = response.data is Map ? response.data['error'] : null;
      throw AuthException(details?.toString() ?? 'Publication request could not be created.');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> decideApproval({
    required String approvalId,
    required bool approve,
  }) async {
    _userId;
    final response = await client.functions.invoke('agent-approval', body: {
      'approval_id': approvalId,
      'decision': approve ? 'approve' : 'reject',
    });
    if (response.status < 200 || response.status >= 300) {
      throw const AuthException('The approval could not be recorded.');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }
}
