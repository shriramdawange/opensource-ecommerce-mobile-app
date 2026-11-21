import 'package:flutter/material.dart';

import '../../../../core/supabase/artbook_supabase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/repositories/artbook_cart_repository.dart';

class ArtBookCartPage extends StatefulWidget {
  const ArtBookCartPage({super.key});

  @override
  State<ArtBookCartPage> createState() => _ArtBookCartPageState();
}

class _ArtBookCartPageState extends State<ArtBookCartPage> {
  late final ArtBookCartRepository _repository;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ArtBookCartRepository(client: ArtBookSupabase.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repository.getCartItems();
      if (mounted) setState(() => _items = rows);
    } catch (error) {
      if (mounted) {
        setState(() {
          _items = [];
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _product(Map<String, dynamic> item) {
    final value = item['products'];
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }

  double get _subtotal => _items.fold<double>(0, (sum, item) {
    final product = _product(item);
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
    return sum + price * quantity;
  });

  Future<void> _changeQuantity(Map<String, dynamic> item, int quantity) async {
    setState(() => _working = true);
    try {
      await _repository.setQuantity(
        cartItemId: item['id'].toString(),
        quantity: quantity,
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _remove(Map<String, dynamic> item) async {
    await _changeQuantity(item, 0);
  }

  Future<void> _checkout() async {
    final address = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _ShippingAddressDialog(),
    );
    if (address == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send order request?'),
        content: Text(
          'Your order subtotal is ₹${_subtotal.toStringAsFixed(2)}. '
          'Shipping and tax will be confirmed separately. '
          'Your shipping address will be shared with the artisan. '
          'No payment will be captured at this step.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Review again'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm order request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final userId = ArtBookSupabase.client.auth.currentUser?.id ?? 'buyer';
      final idempotencyKey = '$userId-${DateTime.now().microsecondsSinceEpoch}';
      final result = await _repository.requestOrder(
        shippingAddress: address,
        idempotencyKey: idempotencyKey,
        buyerConfirmed: true,
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order ${result['order_number'] ?? ''} sent to the artisan for approval. No payment taken.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signedIn = ArtBookSupabase.client.auth.currentUser != null;

    if (!signedIn) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
        appBar: AppBar(
          title: const Text('Your Cart'),
          backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 54, color: Color(0xFF8B735F)),
                const SizedBox(height: 12),
                const Text('Sign in to use your cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Your cart is saved to your ArtBook account.', textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 14),
                      OutlinedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ))
              : _items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 54, color: Color(0xFF8B735F)),
                            SizedBox(height: 12),
                            Text('Your cart is empty', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                            SizedBox(height: 6),
                            Text('Explore handmade creations and add something you love.', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final product = _product(item);
                        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                        final price = (product['price'] as num?)?.toDouble() ?? 0;
                        final media = product['product_media'];
                        final imageUrl = media is List && media.isNotEmpty && media.first is Map
                            ? ArtBookSupabase.client.storage
                                .from('artbook-product-media')
                                .getPublicUrl(media.first['storage_path'].toString())
                            : null;

                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.neutral800 : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppColors.neutral700 : const Color(0xFFEDE4D9)),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  color: const Color(0xFFF1E7DA),
                                  child: imageUrl == null
                                      ? const Icon(Icons.image_outlined, color: Color(0xFF96765B))
                                      : Image.network(imageUrl, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['title']?.toString() ?? 'Product unavailable',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 5),
                                    Text('₹${price.toStringAsFixed(2)} each',
                                      style: const TextStyle(color: Color(0xFF8B735F), fontSize: 12)),
                                    const SizedBox(height: 7),
                                    Row(
                                      children: [
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: _working || quantity <= 1
                                              ? null
                                              : () => _changeQuantity(item, quantity - 1),
                                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                                        ),
                                        Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: _working
                                              ? null
                                              : () => _changeQuantity(item, quantity + 1),
                                          icon: const Icon(Icons.add_circle_outline, size: 20),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: _working ? null : () => _remove(item),
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
      bottomNavigationBar: _items.isEmpty || _loading || _error != null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neutral800 : Colors.white,
                  border: Border(top: BorderSide(color: isDark ? AppColors.neutral700 : const Color(0xFFEDE4D9))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.w700))),
                        Text('₹${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Shipping and tax are not included yet. The artisan must approve your request. No payment is taken now.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8B735F)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _working ? null : _checkout,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6F3E2B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(_working ? 'Please wait…' : 'Continue to order request'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ShippingAddressDialog extends StatefulWidget {
  const _ShippingAddressDialog();

  @override
  State<_ShippingAddressDialog> createState() => _ShippingAddressDialogState();
}

class _ShippingAddressDialogState extends State<_ShippingAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postal = TextEditingController();
  final _country = TextEditingController(text: 'India');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    _country.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Shipping address'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _input(_name, 'Recipient name', validator: _required),
                _input(_phone, 'Phone number', validator: _required, keyboard: TextInputType.phone),
                _input(_line1, 'Address line 1', validator: _required),
                _input(_line2, 'Address line 2'),
                _input(_city, 'City', validator: _required),
                _input(_state, 'State', validator: _required),
                _input(_postal, 'PIN code', validator: _required, keyboard: TextInputType.number),
                _input(_country, 'Country', validator: _required),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'recipient_name': _name.text.trim(),
              'phone': _phone.text.trim(),
              'line1': _line1.text.trim(),
              'line2': _line2.text.trim(),
              'city': _city.text.trim(),
              'state': _state.text.trim(),
              'postal_code': _postal.text.trim(),
              'country': _country.text.trim(),
            });
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }
}
