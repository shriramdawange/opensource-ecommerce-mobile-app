/// Bagisto API endpoint
const String bagistoEndpoint =
    'https://your-bagisto-domain.com/graphql';

/// Storefront key for Bagisto API
const String storefrontKey =
    'your_storefront_key_here';

/// Default channel code used by request headers.
const String channelCode = 'default';

/// Default Bagisto channel ID used during app bootstrap.
const int channelId = 1;

/// Company name
const String companyName = 'Your Company Name';

/// Optional base URL for legacy Bagisto home widgets.
///
/// ArtBook's active Supabase-backed navigation does not require a Bagisto
/// storefront. Leave this unset for ArtBook-only builds; configure it only
/// when a legacy Bagisto screen is intentionally enabled.
const String bagistoPublicBaseUrl = String.fromEnvironment(
  'BAGISTO_PUBLIC_BASE_URL',
  defaultValue: '',
);
