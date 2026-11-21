import 'package:flutter/material.dart';

import '../../../../core/supabase/artbook_supabase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/artisan_profile_repository.dart';
import '../../data/models/artisan_profile.dart';

class ArtisanOnboardingPage extends StatefulWidget {
  const ArtisanOnboardingPage({super.key});

  @override
  State<ArtisanOnboardingPage> createState() => _ArtisanOnboardingPageState();
}

class _ArtisanOnboardingPageState extends State<ArtisanOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _craftRegion = TextEditingController();
  final _state = TextEditingController();
  final _traditions = TextEditingController();
  final _languages = TextEditingController(text: 'Marathi, Hindi');
  bool _isPublic = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  ArtisanProfileRepository get _repository =>
      ArtisanProfileRepository(client: ArtBookSupabase.client);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _craftRegion.dispose();
    _state.dispose();
    _traditions.dispose();
    _languages.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _repository.getMyProfile();
      if (!mounted) return;
      if (profile != null) {
        _name.text = profile.publicName;
        _bio.text = profile.bio ?? '';
        _craftRegion.text = profile.craftRegion ?? '';
        _state.text = profile.state ?? '';
        _traditions.text = profile.craftTraditions.join(', ');
        _languages.text = profile.languages.join(', ');
        _isPublic = profile.isPublic;
      }
    } catch (error) {
      if (mounted) _error = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _splitValues(String value) => value
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toSet()
      .toList(growable: false);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _repository.saveProfile(
        publicName: _name.text,
        bio: _bio.text,
        craftRegion: _craftRegion.text,
        state: _state.text,
        craftTraditions: _splitValues(_traditions.text),
        languages: _splitValues(_languages.text),
        isPublic: _isPublic,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artisan profile saved successfully.')),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Artisan Profile'),
        backgroundColor: isDark ? AppColors.neutral900 : AppColors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.neutral800 : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.neutral700 : AppColors.neutral200,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tell buyers the story behind your craft.',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create your ArtBook identity. You control whether your profile is visible publicly.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(
                    controller: _name,
                    label: 'Public artisan / studio name',
                    hint: 'e.g. Savita Warli Kala',
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Enter the name buyers should see.'
                        : null,
                  ),
                  _field(
                    controller: _bio,
                    label: 'Your story',
                    hint: 'Tell buyers about your craft, experience and inspiration.',
                    maxLines: 4,
                  ),
                  _field(
                    controller: _craftRegion,
                    label: 'Craft region / village',
                    hint: 'e.g. Jawhar, Palghar',
                  ),
                  _field(
                    controller: _state,
                    label: 'State',
                    hint: 'e.g. Maharashtra',
                  ),
                  _field(
                    controller: _traditions,
                    label: 'Craft traditions',
                    hint: 'Comma-separated: Warli art, hand painting',
                  ),
                  _field(
                    controller: _languages,
                    label: 'Languages you can use',
                    hint: 'Comma-separated: Marathi, Hindi',
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show my artisan profile publicly'),
                    subtitle: const Text(
                      'When off, your profile remains private and is not listed for buyers.',
                    ),
                    value: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = value),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving…' : 'Save artisan profile'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.neutral800
              : AppColors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
