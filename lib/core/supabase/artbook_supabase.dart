import 'package:supabase_flutter/supabase_flutter.dart';

/// ArtBook's public client configuration.
///
/// The publishable key is designed for client applications and is protected by
/// database grants + Row Level Security. Never place a Supabase secret or
/// service_role key in this file or in the Flutter app.
class ArtBookSupabase {
  ArtBookSupabase._();

  static const String _url = String.fromEnvironment(
    'ARTBOOK_SUPABASE_URL',
    defaultValue: 'https://csyazvpfgbulczbrfnpu.supabase.co',
  );

  static const String _publishableKey = String.fromEnvironment(
    'ARTBOOK_SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_ZYt7L1Q1c3yPMT12FR7H3Q_45T7sWX5',
  );

  static Future<void> initialize() async {
    if (_url.isEmpty || _publishableKey.isEmpty) {
      throw StateError(
        'ArtBook Supabase configuration is missing. Provide '
        'ARTBOOK_SUPABASE_URL and ARTBOOK_SUPABASE_PUBLISHABLE_KEY.',
      );
    }

    await Supabase.initialize(
      url: _url,
      publishableKey: _publishableKey,
      debug: false,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
