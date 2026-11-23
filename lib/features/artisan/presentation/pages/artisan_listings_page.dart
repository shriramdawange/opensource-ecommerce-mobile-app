import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/supabase/artbook_supabase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/artisan_product_repository.dart';
import '../../../agent/data/repositories/artbook_agent_repository.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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



  Future<void> _showPriceGuidance(Map<String, dynamic> product) async {
    final productId = product['id']?.toString();
    if (productId == null) return;

    try {
      final result = await ArtBookAgentRepository(
        client: ArtBookSupabase.client,
      ).getPriceGuidance(productId: productId);

      if (!mounted) return;
      final range = result['price_range'];
      final hasRange = range is Map;
      final body = hasRange
          ? 'Indicative range: ${range['currency'] ?? 'INR'} ${range['min']} – ${range['max']} per ${range['unit'] ?? 'piece'}\\n\\nBased on ${result['comparable_count'] ?? 0} verified observations. Confidence: ${result['confidence'] ?? 'not available'}.'
          : (result['message']?.toString() ??
              'There is not enough verified comparable market data to suggest a price.');

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Market price guidance'),
          content: Text(
            '$body\\n\\nThis is an indicative comparison, not a guaranteed price or appraisal. You choose the final selling price.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Price guidance unavailable: $error')),
      );
    }
  }

  Future<void> _showBuyerMatches(Map<String, dynamic> product) async {
    final productId = product['id']?.toString();
    if (productId == null) return;

    try {
      final matches = await ArtBookAgentRepository(
        client: ArtBookSupabase.client,
      ).matchBuyers(productId: productId);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Matching buyer requirements'),
          content: SizedBox(
            width: 420,
            child: matches.isEmpty
                ? const Text(
                    'No matching public buyer requirements were found yet. Ask buyers to post their requirements in ArtBook.',
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: matches.length > 6 ? 6 : matches.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      final score = (match['match_score'] as num?)?.toDouble() ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match['title']?.toString() ?? 'Buyer requirement',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${score.toStringAsFixed(0)}% match · Qty ${match['quantity'] ?? 1}',
                            style: const TextStyle(color: Color(0xFF8B735F), fontSize: 12),
                          ),
                          if ((match['description'] ?? '').toString().isNotEmpty)
                            Text(match['description'].toString()),
                          if (match['match_reasons'] is List)
                            Text(
                              (match['match_reasons'] as List).join(' · '),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF8B735F)),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Buyer matching unavailable: $error')),
      );
    }
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
        throw StateError('The publication approval was not created.');
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
    const clay = Color(0xFF98543D);
    const paper = Color(0xFFFAF8F4);
    const ink = Color(0xFF292720);
    const muted = Color(0xFF817D73);
    final background = isDark ? AppColors.neutral900 : paper;
    final surface = isDark ? AppColors.neutral800 : Colors.white;
    final primaryText = isDark ? Colors.white : ink;
    final published = _products.where((p) => p['status'] == 'published').length;
    final inReview = _products.where((p) => p['status'] == 'submitted').length;
    final drafts = _products.where((p) => p['status'] == 'draft').length;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        titleSpacing: 20,
        title: Text('My listings', style: TextStyle(color: primaryText, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -.4)),
        actions: [
          IconButton(onPressed: _load, tooltip: 'Refresh listings', icon: Icon(Icons.refresh_rounded, color: primaryText)),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProduct,
        backgroundColor: clay,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create listing', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: clay))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.cloud_off_outlined, size: 42, color: clay),
                      const SizedBox(height: 12),
                      Text('Could not load your listings', style: TextStyle(color: primaryText, fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, style: FilledButton.styleFrom(backgroundColor: clay), child: const Text('Try again')),
                    ]),
                  ),
                )
              : RefreshIndicator(
                  color: clay,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF56382E), Color(0xFF98543D), Color(0xFFB87552)],
                          ),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('YOUR CREATOR STUDIO', style: TextStyle(color: Color(0xFFFFDDC9), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.7)),
                          const SizedBox(height: 8),
                          const Text('Every piece has\na place here.', style: TextStyle(color: Colors.white, fontSize: 27, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: -.5)),
                          const SizedBox(height: 8),
                          const Text('Manage your creations, follow their progress and connect with buyers.', style: TextStyle(color: Color(0xFFF4E6DD), fontSize: 12, height: 1.45)),
                          const SizedBox(height: 18),
                          Row(children: [
                            _listingMetric('Published', published),
                            const SizedBox(width: 9),
                            _listingMetric('In review', inReview),
                            const SizedBox(width: 9),
                            _listingMetric('Drafts', drafts),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 23),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('YOUR CATALOGUE', style: TextStyle(color: clay, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
                          const SizedBox(height: 5),
                          Text('Your creations', style: TextStyle(color: primaryText, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                        ])),
                        Text('${_products.length} total', style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 13),
                      if (_products.isEmpty)
                        Container(
                          padding: const EdgeInsets.fromLTRB(22, 28, 22, 25),
                          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: isDark ? AppColors.neutral700 : const Color(0xFFECE7DF))),
                          child: Column(children: [
                            Container(width: 66, height: 66, decoration: BoxDecoration(color: const Color(0xFFF1E5DC), borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.palette_outlined, color: clay, size: 30)),
                            const SizedBox(height: 15),
                            Text('Your first creation starts here', style: TextStyle(color: primaryText, fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 7),
                            const Text('Add a few photos and tell the story behind your craft. You can save it as a draft and finish whenever you are ready.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
                            const SizedBox(height: 17),
                            OutlinedButton.icon(onPressed: _createProduct, icon: const Icon(Icons.add_rounded), label: const Text('Create your first listing'), style: OutlinedButton.styleFrom(foregroundColor: clay, side: const BorderSide(color: clay))),
                          ]),
                        )
                      else
                        ..._products.map((product) {
                          final media = product['product_media'] as List? ?? const [];
                          final status = product['status']?.toString() ?? 'draft';
                          final title = product['title']?.toString() ?? 'Untitled creation';
                          String? imageUrl;
                          if (media.isNotEmpty && media.first is Map && media.first['storage_path'] != null) {
                            final first = media.first;
                            final bucket = first['storage_bucket']?.toString() ?? 'artbook-product-media';
                            imageUrl = ArtBookSupabase.client.storage.from(bucket).getPublicUrl(first['storage_path'].toString());
                          }
                          final statusLabel = switch (status) {
                            'published' => 'Published',
                            'submitted' => 'In review',
                            'rejected' => 'Needs changes',
                            _ => 'Draft',
                          };
                          final statusColor = switch (status) {
                            'published' => const Color(0xFF39704F),
                            'submitted' => const Color(0xFF9A6A25),
                            'rejected' => const Color(0xFFB34E43),
                            _ => const Color(0xFF81796E),
                          };
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? AppColors.neutral700 : const Color(0xFFECE7DF))),
                            child: Padding(
                              padding: const EdgeInsets.all(11),
                              child: Column(children: [
                                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 92,
                                      height: 104,
                                      color: const Color(0xFFEDE4D8),
                                      child: imageUrl == null
                                          ? const Icon(Icons.image_outlined, color: Color(0xFF9A806A), size: 30)
                                          : Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Color(0xFF9A806A))),
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: statusColor.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)), child: Text(statusLabel.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .7))),
                                    const SizedBox(height: 8),
                                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: primaryText, fontSize: 14, height: 1.2, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 6),
                                    Text('₹${product['price'] ?? '—'}', style: const TextStyle(color: clay, fontSize: 17, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text('${media.length} photo(s)', style: const TextStyle(color: muted, fontSize: 10)),
                                  ])),
                                ]),
                                if (status == 'draft' || status == 'submitted')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: SizedBox(width: double.infinity, child: FilledButton.tonalIcon(
                                      onPressed: () => _requestPublication(product),
                                      icon: const Icon(Icons.fact_check_outlined, size: 17),
                                      label: const Text('Review & publish'),
                                      style: FilledButton.styleFrom(foregroundColor: clay, backgroundColor: clay.withValues(alpha: .10), padding: const EdgeInsets.symmetric(vertical: 11)),
                                    )),
                                  ),
                                if (status == 'published')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 9),
                                    child: Row(children: [
                                      Expanded(child: OutlinedButton.icon(onPressed: () => _showPriceGuidance(product), icon: const Icon(Icons.insights_outlined, size: 16), label: const Text('Price insights'), style: OutlinedButton.styleFrom(foregroundColor: clay, side: BorderSide(color: clay.withValues(alpha: .35))))),
                                      const SizedBox(width: 9),
                                      Expanded(child: OutlinedButton.icon(onPressed: () => _showBuyerMatches(product), icon: const Icon(Icons.people_outline_rounded, size: 16), label: const Text('Find buyers'), style: OutlinedButton.styleFrom(foregroundColor: clay, side: BorderSide(color: clay.withValues(alpha: .35))))),
                                    ]),
                                  ),
                              ]),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _listingMetric(String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white.withValues(alpha: .12))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$value', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xFFF4E6DD), fontSize: 9, fontWeight: FontWeight.w600)),
        ]),
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
  final _floorPrice = TextEditingController();
  final _voiceDescription = TextEditingController();
  final _picker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();

  late final String _agentIdempotencyKey = 'listing-${DateTime.now().microsecondsSinceEpoch}';
  String _language = 'mr-IN';
  bool _listening = false;
  bool _aiWorking = false;
  String? _agentCaseId;
  List<String> _agentMediaPaths = [];

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
    _floorPrice.dispose();
    _voiceDescription.dispose();
    _speech.stop();
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


  String _contentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'avif' => 'image/avif',
      _ => 'image/jpeg',
    };
  }

  Future<void> _toggleVoiceInput() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          setState(() => _listening = status == 'listening');
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _listening = false;
            _error = error.errorMsg;
          });
        },
      );

      if (!available) {
        setState(() => _error = 'Speech recognition is not available on this device.');
        return;
      }

      await _speech.listen(
        localeId: _language.replaceAll('-', '_'),
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _voiceDescription.text = result.recognizedWords;
            _voiceDescription.selection = TextSelection.fromPosition(
              TextPosition(offset: _voiceDescription.text.length),
            );
          });
        },
      );
      if (mounted) setState(() => _listening = true);
    } catch (error) {
      if (mounted) setState(() => _error = 'Voice input failed: $error');
    }
  }

  Future<void> _generateWithArtBookAI() async {
    if (_voiceDescription.text.trim().isEmpty && _imageBytes == null) {
      setState(() {
        _error = 'Describe your craft or attach a product photo before asking ArtBook AI.';
      });
      return;
    }

    setState(() {
      _aiWorking = true;
      _error = null;
    });

    try {
      final mediaPaths = <String>[];
      if (_image != null && _imageBytes != null) {
        final path = await widget.repository.uploadAgentImage(
          bytes: _imageBytes!,
          fileName: _image!.name,
          contentType: _contentType(_image!.name),
        );
        mediaPaths.add(path);
      }

      final response = await ArtBookAgentRepository(
        client: ArtBookSupabase.client,
      ).startListing(
        language: _language,
        voiceTranscript: _voiceDescription.text.trim(),
        mediaPaths: mediaPaths,
        artisanNotes: 'The artisan will review and edit every suggested field before saving.',
        idempotencyKey: _agentIdempotencyKey,
      );

      final draft = response['draft'];
      if (draft is! Map) {
        throw StateError(
          'ArtBook AI did not return a reviewed listing draft. Please try again.',
        );
      }

      final values = Map<String, dynamic>.from(draft);
      if (!mounted) return;

      setState(() {
        _agentCaseId = response['case_id']?.toString();
        _agentMediaPaths = mediaPaths;
        _title.text = values['title']?.toString() ?? '';
        _description.text = values['description']?.toString() ??
            values['short_description']?.toString() ?? '';
        _story.text = values['craft_story']?.toString() ?? '';
        _origin.text = values['craft_origin_suggestion']?.toString() ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI draft created. Review every detail before saving.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      setState(() {
        _error = message.contains('ARTBOOK_AI_PROVIDER_NOT_CONFIGURED')
            ? 'ArtBook AI needs an AI provider configured in Supabase Edge Function secrets. You can still create this listing manually.'
            : 'Could not generate the AI draft: $message';
      });
    } finally {
      if (mounted) setState(() => _aiWorking = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final floorText = _floorPrice.text.trim();
      final floorPrice = floorText.isEmpty ? null : double.tryParse(floorText);
      if (floorText.isNotEmpty && (floorPrice == null || floorPrice < 0)) {
        throw StateError('Enter a valid minimum acceptable price.');
      }

      if (_agentCaseId != null) {
        final result = await ArtBookAgentRepository(
          client: ArtBookSupabase.client,
        ).saveListingDraft(
          caseId: _agentCaseId!,
          title: _title.text,
          description: _description.text,
          craftStory: _story.text,
          craftOrigin: _origin.text,
          categoryId: _categoryId ?? '',
          price: double.parse(_price.text.trim()),
          floorPrice: floorPrice,
          availableQuantity: int.parse(_quantity.text.trim()),
          minimumOrderQuantity: int.parse(_minimumOrder.text.trim()),
          mediaPaths: _agentMediaPaths,
        );
        _createdDraftId = (result['product'] as Map?)?['id']?.toString();
      } else {
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
            floorPrice: floorPrice,
          );
          _createdDraftId = draft['id'].toString();
        }

        if (_image != null && _imageBytes != null) {
          await widget.repository.uploadProductImage(
            productId: _createdDraftId!,
            bytes: _imageBytes!,
            fileName: _image!.name,
            contentType: _contentType(_image!.name),
            altText: _title.text,
          );
        }
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.neutral800 : const Color(0xFFF2E8DC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Describe your craft. ArtBook helps with the listing.',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _language,
                          decoration: const InputDecoration(
                            labelText: 'Voice / listing language',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'mr-IN', child: Text('Marathi')),
                            DropdownMenuItem(value: 'hi-IN', child: Text('Hindi')),
                            DropdownMenuItem(value: 'en-IN', child: Text('English')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _language = value);
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _voiceDescription,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Describe the product and how it is made',
                            hintText: 'You can type or use the microphone.',
                            border: OutlineInputBorder(),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _toggleVoiceInput,
                                icon: Icon(_listening ? Icons.stop : Icons.mic_none),
                                label: Text(_listening ? 'Stop recording' : 'Speak'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _aiWorking ? null : _generateWithArtBookAI,
                                icon: _aiWorking
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.auto_awesome),
                                label: Text(_aiWorking ? 'Preparing…' : 'Create with AI'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'AI suggestions are not facts. Check the craft name, materials, origin and story before saving.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF8B735F)),
                        ),
                        if (_agentCaseId != null)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'AI draft ready for your review.',
                              style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
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
                  TextFormField(
                    controller: _floorPrice,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Your minimum acceptable price (optional)',
                      helperText: 'Private to you. The buyer and public listing cannot see this value.',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      final amount = double.tryParse(text);
                      final askingPrice = double.tryParse(_price.text.trim());
                      if (amount == null || amount < 0) return 'Enter a valid price.';
                      if (askingPrice != null && amount > askingPrice) {
                        return 'Your minimum price cannot exceed the listing price.';
                      }
                      return null;
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
