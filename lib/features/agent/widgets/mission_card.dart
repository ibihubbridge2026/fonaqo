import 'package:flutter/material.dart';

class MissionCard extends StatelessWidget {
  final String title;
  final String location;
  final String amount;
  final String status;
  final String? client;
  final String? distance;
  final bool? urgent;
  final VoidCallback? onTap;

  const MissionCard({
    super.key,
    required this.title,
    required this.location,
    required this.amount,
    this.status = 'Disponible',
    this.client,
    this.distance,
    this.urgent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    const Color(0xFFFFD400).withValues(alpha: 0.15),
                child: const Icon(
                  Icons.work_outline,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 13,
                      ),
                    ),
                    if (client != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 15,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            client!,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: const TextStyle(
                      color: Color(0xFFE0B800),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: urgent == true
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      urgent == true ? 'Urgent' : status,
                      style: TextStyle(
                        color: urgent == true ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (distance != null) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  distance!,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD400),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Voir',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
