class ArtisanProfile {
  final String id;
  final String userId;
  final String publicName;
  final String? publicSlug;
  final String? bio;
  final String? craftRegion;
  final String? state;
  final String country;
  final List<String> craftTraditions;
  final List<String> languages;
  final int? yearsOfExperience;
  final String onboardingStatus;
  final String verificationStatus;
  final bool isPublic;

  const ArtisanProfile({
    required this.id,
    required this.userId,
    required this.publicName,
    this.publicSlug,
    this.bio,
    this.craftRegion,
    this.state,
    this.country = 'India',
    this.craftTraditions = const [],
    this.languages = const [],
    this.yearsOfExperience,
    this.onboardingStatus = 'draft',
    this.verificationStatus = 'unverified',
    this.isPublic = false,
  });

  factory ArtisanProfile.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic value) {
      if (value is! List) return const [];
      return value.map((item) => item.toString()).toList(growable: false);
    }

    return ArtisanProfile(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      publicName: json['public_name']?.toString() ?? '',
      publicSlug: json['public_slug']?.toString(),
      bio: json['bio']?.toString(),
      craftRegion: json['craft_region']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString() ?? 'India',
      craftTraditions: strings(json['craft_traditions']),
      languages: strings(json['languages']),
      yearsOfExperience: json['years_of_experience'] is num
          ? (json['years_of_experience'] as num).toInt()
          : int.tryParse(json['years_of_experience']?.toString() ?? ''),
      onboardingStatus: json['onboarding_status']?.toString() ?? 'draft',
      verificationStatus: json['verification_status']?.toString() ?? 'unverified',
      isPublic: json['is_public'] == true,
    );
  }
}
