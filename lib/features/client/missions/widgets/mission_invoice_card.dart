import 'package:flutter/material.dart';

import 'package:fonaco/core/constants/app_constants.dart';
import 'package:fonaco/core/models/mission_model.dart';

const _kYellow = Color(0xFFFFD400);
const _kOrangeTotal = Color(0xFFFFB800);

/// Facture épurée affichée sur le détail mission (design tableau noir).
class MissionInvoiceCard extends StatelessWidget {
  final MissionModel mission;
  final String? clientEmail;
  final String? agentEmail;
  final VoidCallback? onDownload;

  const MissionInvoiceCard({
    super.key,
    required this.mission,
    this.clientEmail,
    this.agentEmail,
    this.onDownload,
  });

  String get _invoiceNumber {
    final date = mission.createdAt ?? DateTime.now();
    final idPart = mission.id.length >= 8 ? mission.id.substring(0, 8) : mission.id;
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'INV-$y$m$d-$idPart';
  }

  List<_InvoiceLine> get _lines {
    final lines = <_InvoiceLine>[];
    final serviceAmount = mission.serviceAmount ?? mission.price;
    final purchase = mission.purchaseAmount ?? 0;

    final descriptionLabel = mission.isVocalDescription
        ? 'Description Vocale'
        : (mission.description.trim().isNotEmpty
            ? mission.description.trim()
            : mission.title);

    lines.add(_InvoiceLine(
      description: descriptionLabel,
      category: mission.category ?? 'Service',
      amount: serviceAmount,
    ));

    if (mission.isUrgent) {
      lines.add(const _InvoiceLine(
        description: 'Mission Urgente',
        category: 'Option',
        amount: AppConstants.optionCost,
      ));
    }

    if (mission.isConfidential) {
      lines.add(const _InvoiceLine(
        description: 'Agent Interne Fonaqo',
        category: 'Option',
        amount: AppConstants.optionCost,
      ));
    }

    final platformFee = mission.serviceFee != null
        ? (mission.serviceFee! -
            (mission.isUrgent ? AppConstants.optionCost : 0) -
            (mission.isConfidential ? AppConstants.optionCost : 0))
        : serviceAmount * 0.10;

    if (platformFee > 0) {
      lines.add(_InvoiceLine(
        description: 'Frais plateforme',
        category: 'FONACO',
        amount: platformFee,
      ));
    }

    if (purchase > 0) {
      lines.add(_InvoiceLine(
        description: 'Montant achats',
        category: 'Achats',
        amount: purchase,
      ));
    }

    return lines;
  }

  double get _totalTtc =>
      _lines.fold(0.0, (sum, line) => sum + line.amount);

  static String _formatDisplayDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final invoiceDate = mission.createdAt ?? DateTime.now();
    final clientName = mission.clientName ?? 'Client';
    final agentName = mission.agentName ?? 'Non assigné';
    final agentPhone = mission.agentPhone ?? '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/icon/fonaco.png',
                      height: 32,
                      width: 32,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.business,
                        size: 32,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Fonaqo',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1a1a2e),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Facture N° $_invoiceNumber',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDisplayDate(invoiceDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: _kYellow,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PartyBlock(
                    badgeLabel: 'AGENT',
                    name: agentName,
                    phone: agentPhone,
                    email: agentEmail ?? '—',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PartyBlock(
                    badgeLabel: 'FACTURÉ À',
                    name: clientName,
                    phone: '—',
                    email: clientEmail ?? '—',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _InvoiceTable(lines: _lines),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _kOrangeTotal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL TTC',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '${_totalTtc.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (onDownload != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: OutlinedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.file_download, size: 20),
                label: const Text(
                  'Télécharger la facture',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PartyBlock extends StatelessWidget {
  final String badgeLabel;
  final String name;
  final String phone;
  final String email;

  const _PartyBlock({
    required this.badgeLabel,
    required this.name,
    required this.phone,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: _kYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              badgeLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(name, style: _infoStyle),
        Text('Contact : $phone', style: _infoStyle),
        Text('Email : $email', style: _infoStyle),
      ],
    );
  }

  static const _infoStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
    height: 1.5,
  );
}

class _InvoiceLine {
  final String description;
  final String category;
  final double amount;

  const _InvoiceLine({
    required this.description,
    required this.category,
    required this.amount,
  });
}

class _InvoiceTable extends StatelessWidget {
  final List<_InvoiceLine> lines;

  const _InvoiceTable({required this.lines});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      border: TableBorder.all(color: const Color(0xFFE0E0E0)),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: _kYellow),
          children: [
            _headerCell('Description'),
            _headerCell('Catégorie'),
            _headerCell('Montant'),
          ],
        ),
        ...lines.map(
          (line) => TableRow(
            children: [
              _bodyCell(line.description),
              _bodyCell(line.category),
              _bodyCell('${line.amount.toStringAsFixed(0)} FCFA'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            color: Colors.black,
          ),
        ),
      );

  Widget _bodyCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 11,
            color: Colors.black87,
            height: 1.35,
          ),
        ),
      );
}
