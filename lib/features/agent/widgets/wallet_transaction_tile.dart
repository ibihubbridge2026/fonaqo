import 'package:flutter/material.dart';

class WalletTransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color? iconColor;
  final Color? amountColor;
  final bool isIncome;
  final VoidCallback? onTap;

  const WalletTransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    this.iconColor,
    this.amountColor,
    this.isIncome = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flowColor = iconColor ??
        (isIncome
            ? const Color(0xFF2E7D32)
            : const Color(0xFFC62828));

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: flowColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: flowColor,
          size: 18,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 10,
        ),
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: amountColor ?? flowColor,
        ),
      ),
    );
  }
}
