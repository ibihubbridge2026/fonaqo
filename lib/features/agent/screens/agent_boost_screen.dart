import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/services/feexpay_service.dart';
import 'package:fonaco/features/agent/data/models/boost_plan_model.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';

/// Écran boost agent — plans API, boost actif, achat wallet/FeexPay.
class AgentBoostScreen extends StatefulWidget {
  const AgentBoostScreen({super.key});

  @override
  State<AgentBoostScreen> createState() => _AgentBoostScreenState();
}

class _AgentBoostScreenState extends State<AgentBoostScreen> {
  int _selectedIndex = 0;
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await context.read<AgentProvider>().fetchBoostData();
    await context.read<AgentProvider>().fetchWalletDetails();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _purchase(BoostPlanModel plan) async {
    final name = plan.name;
    final price = plan.price;

    final method = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Activer $name',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Portefeuille FONACO'),
              subtitle: Text(
                '${context.read<AgentProvider>().balance.toStringAsFixed(0)} FCFA',
              ),
              onTap: () => Navigator.pop(ctx, 'wallet'),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('FeexPay'),
              onTap: () => Navigator.pop(ctx, 'feexpay'),
            ),
          ],
        ),
      ),
    );

    if (method == null || !mounted) return;
    setState(() => _purchasing = true);

    try {
      final provider = context.read<AgentProvider>();
      String? transactionId;

      if (method == 'wallet') {
        if (provider.balance < price) {
          _snack('Solde insuffisant', isError: true);
          return;
        }
      } else {
        final result = await FeexPayService.instance.requestPayment(
          context: context,
          amount: price,
          description: 'Boost $name',
          purpose: 'boost_purchase',
          metadata: {'plan_name': name},
        );
        if (result == null || !mounted) return;
        transactionId = result.externalReference;
      }

      final ok = await provider.profileRepository.purchaseBoost(
        plan.id,
        price,
        planName: name,
        paymentMethod: method == 'feexpay' ? 'feexpay' : 'wallet',
        transactionId: transactionId,
      );

      if (!mounted) return;
      if (ok) {
        await _load();
        _snack('$name activé jusqu\'à expiration');
      } else {
        _snack('Échec de l\'achat', isError: true);
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgentProvider>();
    final plans = provider.boostPlans;
    final active = provider.activeBoost;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Booster mon profil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD400)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFFFFD400),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (active != null) _ActiveBoostCard(boost: active),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD400), Color(0xFFFFC107)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Priorité missions',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Accédez aux nouvelles missions 10 min avant les autres agents.',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.75),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Choisir un pass',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (plans.isEmpty)
                    const Text('Aucun plan disponible pour le moment.')
                  else
                    ...List.generate(plans.length, (index) {
                      final plan = BoostPlanModel.fromJson(plans[index]);
                      final selected = _selectedIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFFFD400)
                                  : Colors.grey.shade200,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${plan.durationHours > 0 ? plan.durationHours : '?'} h · x${plan.visibilityMultiplier} visibilité',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${plan.price.toStringAsFixed(0)} F',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: Color(0xFFE0B800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _purchasing || plans.isEmpty
                          ? null
                          : () => _purchase(
                                BoostPlanModel.fromJson(plans[_selectedIndex]),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD400),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _purchasing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Activer le boost',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ActiveBoostCard extends StatelessWidget {
  final Map<String, dynamic> boost;

  const _ActiveBoostCard({required this.boost});

  @override
  Widget build(BuildContext context) {
    final plan = boost['plan'];
    final planName = plan is Map
        ? plan['name']?.toString() ?? 'Boost actif'
        : 'Boost actif';
    final expires = boost['expires_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                if (expires.isNotEmpty)
                  Text(
                    'Expire : ${expires.substring(0, 16).replaceFirst('T', ' ')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade800,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
