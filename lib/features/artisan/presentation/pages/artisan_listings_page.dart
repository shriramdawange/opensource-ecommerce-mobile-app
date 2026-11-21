import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/supabase/artbook_supabase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/artisan_product_repository.dart';

class ArtisanListingsPage extends StatefulWidget {
  const ArtisanListingsPage({super.key});

  @override
  State<ArtisanListingsPage> createState() => _ArtisanListingsPageState();
}

class _ArtisanListingsPageState extends State<ArtisanListingsPage> {
  late final ArtisanProductRepository _repository;
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ArtisanProductRepository(client: ArtBookSupabase.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _repository.getMyProducts();
      if (mounted) setState(() => _products = products);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createProduct() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateArtisanProductPage(repository: _repository),
      ),
    );
    if (created == true && mounted) _load();
  }


  Future<void> _requestPublication(Map<String, dynamic> product) async {
    final productId = product['id']?.toString();
    final title = product['title']?.toString() ?? 'this product';
    if (productId == null || productId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publish this listing?'),
        content: Text(
          '“$title” will become visible to buyers on the ArtBook marketplace. '
          'Please confirm that the product details, price, craft story and photos are accurate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep as draft'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm publication'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final request = await _repository.requestListingPublication(
        productId: productId,
      );
      final approvalId = request['approval_id']?.toString();
      if (approvalId == null || approvalId.isEmpty) {
        throw const AuthException('The publication approval was not created.');
      }

      await _repository.decideApproval(
        approvalId: approvalId,
        approve: true,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your product is now published on ArtBook.')),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not publish listing: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.neutral50,
      appBar: AppBar(
        title: const Text('My ArtBook Listings'),
        backgroundColor: isDark ? AppColors.neutral900 : AppColors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProduct,
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('New listing'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _products.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'Your craft deserves to be seen.',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Create your first product listing. It will be saved as a draft until it is reviewed and approved.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: _products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final media = product['product_media'] as List? ?? const [];
                          final status = product['status']?.toString() ?? 'draft';
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.palette_outlined),
                                    ),
                                    title: Text(product['title']?.toString() ?? 'Untitled'),
                                    subtitle: Text(
                                      '₹${product['price'] ?? '—'}  ·  ${status.toUpperCase()}  ·  ${media.length} photo(s)',
                                    ),
                                    isThreeLine: true,
                                  ),
                                  if (status == 'draft' || status == 'submitted')
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _requestPublication(product),
                                        icon: const Icon(Icons.publish_outlined),
                                        label: const Text('Review & publish'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class CreateArtisanProductPage extends StatefulWidget {
  final ArtisanProductRepository repository;

  const CreateArtisanProductPage({super.key, required this.repository});

  @override
  State<CreateArtisanProductPage> createState() => _CreateArtisanProductPageState();
}

class _CreateArtisanProductPageState extends State<CreateArtisanProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _story = TextEditingController();
  final _origin = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _minimumOrder = TextEditingController(text: '1');
  final _picker = ImagePicker();

  List<Map<String, dynamic>> _categories = [];
  String? _categoryId;
  XFile? _image;
  Uint8List? _imageBytes;
  String? _createdDraftId;
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
    _story.dispose();
    _origin.dispose();
    _price.dispose();
    _quantity.dispose();
    _minimumOrder.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.repository.getCraftCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) {
      setState(() {
        _image = file;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_createdDraftId == null) {
        final draft = await widget.repository.createDraft(
          title: _title.text,
          description: _description.text,
          craftStory: _story.text,
          craftOrigin: _origin.text,
          categoryId: _categoryId ?? '',
          price: double.parse(_price.text.trim()),
          availableQuantity: int.parse(_quantity.text.trim()),
          minimumOrderQuantity: int.parse(_minimumOrder.text.trim()),
        );
        _createdDraftId = draft['id'].toString();
      }

      if (_image != null && _imageBytes != null) {
        final extension = _image!.name.split('.').last.toLowerCase();
        final contentType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          'avif' => 'image/avif',
          _ => 'image/jpeg',
        };
        await widget.repository.uploadProductImage(
          productId: _createdDraftId!,
          bytes: _imageBytes!,
          fileName: _image!.name,
          contentType: contentType,
          altText: _title.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft listing saved to ArtBook.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Create Product Listing'),
        backgroundColor: isDark ? AppColors.neutral900 : AppColors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Product name'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _categoryId,
                    decoration: const InputDecoration(labelText: 'Craft category'),
                    items: _categories
                        .map((category) => DropdownMenuItem<String>(
                              value: category['id'].toString(),
                              child: Text(category['name'].toString()),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Product description'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _story,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Story behind the craft',
                      helperText: 'Keep artisan-provided facts separate from AI suggestions.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _origin,
                    decoration: const InputDecoration(labelText: 'Craft origin / region'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Listing price (INR)'),
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');
                      return amount == null || amount < 0 ? 'Enter a valid price.' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantity,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Available qty'),
                          validator: (value) {
                            final amount = int.tryParse(value?.trim() ?? '');
                            return amount == null || amount < 0 ? 'Invalid quantity.' : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minimumOrder,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Minimum order'),
                          validator: (value) {
                            final amount = int.tryParse(value?.trim() ?? '');
                            return amount == null || amount < 1 ? 'Minimum is 1.' : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(_image == null ? 'Add product photo' : 'Change product photo'),
                  ),
                  if (_imageBytes != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_imageBytes!, height: 180, fit: BoxFit.cover),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_saving ? 'Saving…' : 'Save draft listing'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'New products are saved as drafts. Publishing is server-controlled and will require the artisan approval workflow.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
