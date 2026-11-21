import 'package:flutter/material.dart';

import '../../../../core/supabase/artbook_supabase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../agent/data/repositories/artbook_agent_repository.dart';
import '../../data/repositories/artbook_orders_repository.dart';

class ArtBookOrdersPage extends StatefulWidget {
  const ArtBookOrdersPage({super.key});

  @override
  State<ArtBookOrdersPage> createState() => _ArtBookOrdersPageState();
}

class _ArtBookOrdersPageState extends State<ArtBookOrdersPage> {
  late final ArtBookOrdersRepository _repository;
  List<Map<String, dynamic>> _orders = [];
  Map<String, String> _approvals = {};
  bool _loading = true;
  String? _error;
  final Set<String> _working = {};

  @override
  void initState() {
    super.initState();
    _repository = ArtBookOrdersRepository(client: ArtBookSupabase.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getMyOrders(),
        _repository.getPendingArtisanApprovals(),
      ]);
      if (!mounted) return;
      setState(() {
        _orders = results[0] as List<Map<String, dynamic>>;
        _approvals = results[1] as Map<String, String>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(String orderId, bool approve) async {
    final approvalId = _approvals[orderId];
    if (approvalId == null) return;

    setState(() => _working.add(orderId));
    try {
      await ArtBookAgentRepository(client: ArtBookSupabase.client).decideApproval(
        approvalId: approvalId,
        approve: approve,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve
              ? 'Order accepted. Stock has been reserved.'
              : 'Order request declined.'),
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update order: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _working.remove(orderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = ArtBookSupabase.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 52, color: Color(0xFF8B735F)),
                            SizedBox(height: 12),
                            Text('No orders yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            SizedBox(height: 6),
                            Text('Your purchases and artisan order requests will appear here.', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final id = order['id'].toString();
                          final orderNumber = order['order_number']?.toString() ?? id.substring(0, 8);
                          final status = order['status']?.toString() ?? 'pending';
                          final isArtisan = order['artisan_user_id'] == userId;
                          final items = order['order_items'] is List
                              ? order['order_items'] as List
                              : const [];
                          final approvalId = _approvals[id];
                          final busy = _working.contains(id);
                          final total = (order['total_amount'] as num?)?.toDouble() ?? 0;
                          final currency = order['currency']?.toString() ?? 'INR';

                          return Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.neutral800 : Colors.white,
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: isDark ? AppColors.neutral700 : const Color(0xFFEDE4D9),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        orderNumber,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                      ),
                                    ),
                                    _statusChip(status),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  isArtisan ? 'Buyer order request' : 'Your purchase',
                                  style: const TextStyle(color: Color(0xFF8B735F), fontSize: 12),
                                ),
                                const SizedBox(height: 10),
                                ...items.map((raw) {
                                  final item = raw is Map
                                      ? Map<String, dynamic>.from(raw)
                                      : <String, dynamic>{};
                                  final quantity = item['quantity'] ?? 1;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['product_title_snapshot']?.toString() ?? 'Handmade product',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text('× $quantity'),
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(height: 18),
                                Row(
                                  children: [
                                    const Expanded(child: Text('Order total', style: TextStyle(fontWeight: FontWeight.w700))),
                                    Text(
                                      '$currency \${total.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                  ],
                                ),
                                if (status == 'pending_approval' && !isArtisan) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Waiting for the artisan to review this request. No payment has been captured.',
                                    style: TextStyle(color: Color(0xFF8B735F), fontSize: 12),
                                  ),
                                ],
                                if (approvalId != null && status == 'pending_approval') ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'The buyer is waiting for your decision. Accepting reserves the requested stock.',
                                    style: TextStyle(color: Color(0xFF8B735F), fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: busy ? null : () => _decide(id, false),
                                          child: const Text('Decline'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: busy ? null : () => _decide(id, true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFF6F3E2B),
                                          ),
                                          child: Text(busy ? 'Please wait…' : 'Accept order'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _statusChip(String status) {
    final (label, color) = switch (status) {
      'pending_approval' => ('Awaiting artisan', const Color(0xFF9A6A40)),
      'confirmed' => ('Confirmed', const Color(0xFF2E7D32)),
      'processing' => ('Processing', const Color(0xFF1565C0)),
      'shipped' => ('Shipped', const Color(0xFF1565C0)),
      'delivered' => ('Delivered', const Color(0xFF2E7D32)),
      'cancelled' => ('Cancelled', const Color(0xFFB3261E)),
      'refunded' => ('Refunded', const Color(0xFF6B6B6B)),
      _ => (status, const Color(0xFF6B6B6B)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}
