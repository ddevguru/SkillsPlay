import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _processing = false;
  String? _selectedPlan;

  Future<void> _purchase(String planId) async {
    setState(() { _processing = true; _selectedPlan = planId; });
    try {
      final api = ref.read(apiServiceProvider);
      final checkout = await api.checkout(planId);
      final paymentId = checkout['paymentId'] as String;

      // Mock payment flow — simulate user completing checkout
      await Future.delayed(const Duration(seconds: 1));
      await api.completeMockPayment(paymentId);
      await ref.read(authStateProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription activated! (Mock payment)')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() { _processing = false; _selectedPlan = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscribe')),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (plans) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.star, size: 48),
                    SizedBox(height: 8),
                    Text('Unlock unlimited plays, multiplayer & premium tracks',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text('🧪 Mock payment gateway — no real charges',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...plans.map((plan) => Card(
              child: ListTile(
                title: Text(plan.name),
                subtitle: Text('${plan.priceDisplay}/${plan.interval}'),
                trailing: _processing && _selectedPlan == plan.id
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : FilledButton(
                        onPressed: _processing ? null : () => _purchase(plan.id),
                        child: const Text('Buy'),
                      ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
