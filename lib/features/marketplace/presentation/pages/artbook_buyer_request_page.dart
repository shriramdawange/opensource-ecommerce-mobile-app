import 'package:flutter/material.dart';

import '../../../../core/supabase/artbook_supabase.dart';
import '../../../../core/theme/app_theme.dart';

class ArtBookBuyerRequestPage extends StatefulWidget {
  const ArtBookBuyerRequestPage({super.key});

  @override
  State<ArtBookBuyerRequestPage> createState() => _ArtBookBuyerRequestPageState();
}

class _ArtBookBuyerRequestPageState extends State<ArtBookBuyerRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _region = TextEditingController();
  final _budgetMin = TextEditingController();
  final _budgetMax = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  String? _categoryId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _quantity.dispose();
    _region.dispose();
    _budgetMin.dispose();
    _budgetMax.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final rows = await ArtBookSupabase.client
          .from('craft_categories')
          .select('id,name')
          .eq('is_active', true)
          .order('sort_order');
      if (mounted) {
        setState(() => _categories = List<Map<String, dynamic>>.from(rows));
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final minText = _budgetMin.text.trim();
    final maxText = _budgetMax.text.trim();
    final min = minText.isEmpty ? null : double.tryParse(minText);
    final max = maxText.isEmpty ? null : double.tryParse(maxText);

    if ((minText.isNotEmpty && (min == null || min < 0)) ||
        (maxText.isNotEmpty && (max == null || max < 0))) {
      setState(() => _error = 'Enter valid budget amounts.');
      return;
    }
    if (min != null && max != null && min > max) {
      setState(() => _error = 'Minimum budget cannot exceed maximum budget.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final userId = ArtBookSupabase.client.auth.currentUser?.id;
      if (userId == null) throw StateError('Please sign in again.');

      await ArtBookSupabase.client.from('buyer_requests').insert({
        'buyer_user_id': userId,
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'category_id': _categoryId,
        'quantity': int.parse(_quantity.text.trim()),
        'delivery_region': _region.text.trim().isEmpty ? null : _region.text.trim(),
        'budget_min': min,
        'budget_max': max,
        'currency': 'INR',
        'visibility': 'public',
        'status': 'open',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your buyer requirement is now visible to matching artisans.')),
      );
      Navigator.of(context).pop(true);
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
      backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
      appBar: AppBar(
        title: const Text('Post a Buyer Requirement'),
        backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const Text(
                    'Tell artisans what you are looking for.',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Your public brief includes only the craft requirement and buying criteria. Your contact details are not shown.',
                    style: TextStyle(color: Color(0xFF8B735F), height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _title,
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'What do you need?',
                      hintText: 'e.g. Handwoven cotton table runners',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _categoryId,
                    decoration: const InputDecoration(labelText: 'Craft category'),
                    items: _categories.map((category) => DropdownMenuItem<String>(
                      value: category['id'].toString(),
                      child: Text(category['name'].toString()),
                    )).toList(),
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Requirements',
                      hintText: 'Describe the style, materials, dimensions or customisation you need.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final quantity = int.tryParse(value?.trim() ?? '');
                      return quantity == null || quantity < 1
                          ? 'Enter a quantity of at least 1.'
                          : null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Quantity required',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _region,
                    decoration: const InputDecoration(
                      labelText: 'Delivery region (optional)',
                      hintText: 'e.g. Pune, Maharashtra',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _budgetMin,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Budget minimum (₹)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _budgetMax,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Budget maximum (₹)'),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.campaign_outlined),
                    label: Text(_saving ? 'Publishing…' : 'Publish buyer requirement'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6F3E2B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
