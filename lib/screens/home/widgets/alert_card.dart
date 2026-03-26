import 'package:flutter/material.dart';
import 'package:servisku/config/theme.dart';
import 'package:servisku/utils/service_calculator.dart';

class AlertCard extends StatelessWidget {
  final UpcomingAlert alert;
  final VoidCallback onTap;

  const AlertCard({super.key, required this.alert, required this.onTap});

  Color get _bgColor {
    if (alert.status.isOverdue) return AppColors.danger.withValues(alpha: 0.08);
    return AppColors.warning.withValues(alpha: 0.08);
  }

  Color get _iconColor {
    if (alert.status.isOverdue) return AppColors.danger;
    return AppColors.warning;
  }

  String get _statusText {
    final d = alert.status.daysLeft;
    if (d == null) return '';
    if (d < 0) return 'Terlambat ${d.abs()} hari';
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
          color: _bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _iconColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(alert.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        alert.vehicle.icon,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        alert.vehicle.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    alert.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _iconColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
