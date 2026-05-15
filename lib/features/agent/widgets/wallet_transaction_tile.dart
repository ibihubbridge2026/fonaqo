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
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7CC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.black,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: amountColor ?? (isIncome ? Colors.green : Colors.red),
        ),
      ),
    );
  }
}
