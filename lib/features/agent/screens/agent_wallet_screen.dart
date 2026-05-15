import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import '../providers/agent_provider.dart';
import '../widgets/wallet_transaction_tile.dart';
import '../repository/agent_repository.dart';

class AgentWalletScreen extends StatefulWidget {
  const AgentWalletScreen({super.key});

  @override
  State<AgentWalletScreen> createState() => _AgentWalletScreenState();
}

class _AgentWalletScreenState extends State<AgentWalletScreen> {
  bool _isGeneratingPdf = false;
  final AgentRepository _agentRepository = AgentRepository();

  @override
  void dispose() {
    super.dispose();
  }

  /// Génère le relevé PDF des 30 dernières transactions
  Future<void> _generatePdfStatement() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      final transactions = agentProvider.transactions;
      final balance = agentProvider.balance;

      // Prendre les 30 dernières transactions
      final recentTransactions = transactions.take(30).toList();

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'FONACO',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.Text(
                          'Relevé de Portefeuille',
                          style: pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.grey,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 32),

                // Solde actuel
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.yellow100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Solde Actuel',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${balance.toStringAsFixed(2)} XOF',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),

                // Transactions
                pw.Text(
                  '30 Dernières Transactions',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 16),

                if (recentTransactions.isEmpty)
                  pw.Center(
                    child: pw.Text(
                      'Aucune transaction récente',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey,
                      ),
                    ),
                  )
                else
                  pw.TableHelper.fromTextArray(
                    context: context,
                    data: [
                      ['Date', 'Description', 'Montant'],
                      ...recentTransactions.map((transaction) => [
                            transaction['date'] ?? '',
                            transaction['title'] ?? '',
                            '${transaction['amount'] ?? 0} XOF',
                          ]),
                    ],
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.yellow,
                    ),
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerRight,
                    },
                    cellStyle: pw.TextStyle(
                      fontSize: 10,
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(3),
                      2: const pw.FlexColumnWidth(2),
                    },
                  ),

                pw.SizedBox(height: 32),

                // Footer
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Merci d\'utiliser FONACO',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Ce document est généré automatiquement',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Sauvegarder et imprimer le PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'releé_fonaco_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Relevé PDF généré avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur génération PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentProvider>(
      builder: (context, agentProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  const Text(
                    'Mon Portefeuille',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gérez vos revenus et transactions',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // SOLDE CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFD400),
                          const Color(0xFFFFC700),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD400).withOpacity(.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solde disponible',
                          style: TextStyle(
                            color: Colors.black.withOpacity(.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${agentProvider.balance.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _showWithdrawalBottomSheet(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: const Color(0xFFFFD400),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Retirer mes gains',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ACTIONS RAPIDES
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(Icons.add, 'Recharger'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(Icons.send, 'Transfert'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            _buildQuickAction(Icons.receipt_long, 'Factures'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // RÉSUMÉ DES REVENUS
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Résumé des revenus',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildRevenueRow('Missions terminées', '152'),
                        _buildRevenueRow('Revenus totaux', '1 250 000 FCFA'),
                        _buildRevenueRow('Commission FONACO', '125 000 FCFA'),
                        _buildRevenueRow(
                            'Revenu moyen / mission', '8 200 FCFA'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // TRANSACTIONS RÉCENTES
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Transactions récentes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Navigation vers historique
                              },
                              child: const Text('Voir tout'),
                            ),

                            const SizedBox(height: 8),

                            // Bouton Télécharger relevé
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: _isGeneratingPdf
                                    ? null
                                    : _generatePdfStatement,
                                icon: _isGeneratingPdf
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Icon(Icons.picture_as_pdf,
                                        size: 16),
                                label: Text(
                                  _isGeneratingPdf
                                      ? 'Génération...'
                                      : 'Télécharger mon relevé',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD400),
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Transactions dynamiques
                        ...agentProvider.transactions.map((transaction) {
                          return WalletTransactionTile(
                            title: transaction['title'] ?? 'Transaction',
                            subtitle: transaction['subtitle'] ?? 'Description',
                            amount: transaction['amount']?.toString() ?? '0',
                            icon: transaction['icon'] ?? Icons.swap_horiz,
                            iconColor: transaction['iconColor'] ?? Colors.grey,
                            amountColor:
                                transaction['amountColor'] ?? Colors.black,
                            isIncome: transaction['isIncome'] ?? true,
                            onTap: () {
                              // TODO: Détails transaction
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevenueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7CC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFFFFD400)),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WithdrawalBottomSheet(
        availableBalance: context.read<AgentProvider>().balance,
        onWithdrawalRequested: (amount, provider) async {
          final success = await context
              .read<AgentProvider>()
              .requestWithdrawal(amount, provider);
          if (success) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Demande de retrait envoyée avec succès!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }
}

class _WithdrawalBottomSheet extends StatefulWidget {
  final double availableBalance;
  final Function(double amount, String provider) onWithdrawalRequested;

  const _WithdrawalBottomSheet({
    required this.availableBalance,
    required this.onWithdrawalRequested,
  });

  @override
  State<_WithdrawalBottomSheet> createState() => _WithdrawalBottomSheetState();
}

class _WithdrawalBottomSheetState extends State<_WithdrawalBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  final AgentRepository _agentRepository = AgentRepository();
  bool _isProcessing = false;
  bool _isGeneratingPdf = false;
  String _selectedProvider = 'mtn_momo';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: 60,
            height: 6,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          const SizedBox(height: 24),

          // Titre
          const Text(
            'Retirer mes gains',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Solde disponible: ${widget.availableBalance.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Montant
                const Text(
                  'Montant à retirer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '0 FCFA',
                    prefixText: 'FCFA ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFFFD400)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Opérateur
                const Text(
                  'Opérateur Mobile Money',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedProvider = 'mtn_momo';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedProvider == 'mtn_momo'
                                ? const Color(0xFFFFD400).withOpacity(.2)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedProvider == 'mtn_momo'
                                  ? const Color(0xFFFFD400)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'MTN MoMo',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedProvider = 'moov_flooz';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedProvider == 'moov_flooz'
                                ? const Color(0xFFFFD400).withOpacity(.2)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedProvider == 'moov_flooz'
                                  ? const Color(0xFFFFD400)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Moov Flooz',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Bouton de retrait
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _submitWithdrawal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD400),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Confirmer le retrait',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitWithdrawal() async {
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un montant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Montant invalide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount > widget.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solde insuffisant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.onWithdrawalRequested(amount, _selectedProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Génère le relevé PDF des 30 dernières transactions
  Future<void> _generatePdfStatement() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      final transactions = agentProvider.transactions;
      final balance = agentProvider.balance;

      // Prendre les 30 dernières transactions
      final recentTransactions = transactions.take(30).toList();

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'FONACO',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.Text(
                          'Relevé de Portefeuille',
                          style: pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.grey,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 32),

                // Solde actuel
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.yellow100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Solde Actuel',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${balance.toStringAsFixed(2)} XOF',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),

                // Transactions
                pw.Text(
                  '30 Dernières Transactions',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 16),

                if (recentTransactions.isEmpty)
                  pw.Center(
                    child: pw.Text(
                      'Aucune transaction récente',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey,
                      ),
                    ),
                  )
                else
                  pw.TableHelper.fromTextArray(
                    context: context,
                    data: [
                      ['Date', 'Description', 'Montant'],
                      ...recentTransactions.map((transaction) => [
                            transaction['date'] ?? '',
                            transaction['title'] ?? '',
                            '${transaction['amount'] ?? 0} XOF',
                          ]),
                    ],
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.yellow,
                    ),
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerRight,
                    },
                    cellStyle: pw.TextStyle(
                      fontSize: 10,
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(3),
                      2: const pw.FlexColumnWidth(2),
                    },
                  ),

                pw.SizedBox(height: 32),

                // Footer
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Merci d\'utiliser FONACO',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Ce document est généré automatiquement',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Sauvegarder et imprimer le PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'releé_fonaco_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Relevé PDF généré avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur génération PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }
}
