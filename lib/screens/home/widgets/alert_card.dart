import 'package:flutter/material.dart';
import 'package:servisku/config/theme.dart';
import 'package:servisku/utils/service_calculator.dart';

class AlertCard extends StatelessWidget {
  final UpcomingAlert alert;
  final VoidCallback onTap;

  const AlertCard({super.key, required this.alert, required this.onTap});

  Color get _color =>
      alert.status.isOverdue ? AppColors.danger : AppColors.warning;

  Color get _lightColor =>
      alert.status.isOverdue ? AppColors.dangerLight : AppColors.warningLight;

  String get _statusText {
    final d = alert.status.daysLeft;
    if (d == null) return '';
    if (d < 0) return '${d.abs()}h telat';
    if (d == 0) return 'Hari ini!';
    return '$d hari lagi';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _lightColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(alert.icon, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(alert.vehicle.icon,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          alert.vehicle.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    alert.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
