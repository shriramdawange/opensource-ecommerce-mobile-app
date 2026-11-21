import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/artisan_profile.dart';

class ArtisanProfileRepository {
  final SupabaseClient client;

  const ArtisanProfileRepository({required this.client});

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) {
      throw const AuthException('Please sign in to manage your artisan profile.');
    }
    return id;
  }

  Future<ArtisanProfile?> getMyProfile() async {
    final row = await client
        .from('artisan_profiles')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    if (row == null) return null;
    return ArtisanProfile.fromJson(row);
  }

  Future<ArtisanProfile> saveProfile({
    required String publicName,
    required String bio,
    required String craftRegion,
    required String state,
    required List<String> craftTraditions,
    required List<String> languages,
    required bool isPublic,
  }) async {
    final userId = _userId;
    final existing = await getMyProfile();

    final values = <String, dynamic>{
      'public_name': publicName.trim(),
      'bio': bio.trim(),
      'craft_region': craftRegion.trim(),
      'state': state.trim(),
      'country': 'India',
      'craft_traditions': craftTraditions,
      'languages': languages,
      'onboarding_status': 'completed',
      'is_public': isPublic,
    };

    final Map<String, dynamic> row;
    if (existing == null) {
      row = await client
          .from('artisan_profiles')
          .insert({...values, 'user_id': userId})
          .select()
          .single();
    } else {
      row = await client
          .from('artisan_profiles')
          .update(values)
          .eq('user_id', userId)
          .select()
          .single();
    }

    return ArtisanProfile.fromJson(row);
  }
}
