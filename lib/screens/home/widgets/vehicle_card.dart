import 'package:flutter/material.dart';
import 'package:servisku/config/theme.dart';
import 'package:servisku/models/vehicle.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const VehicleCard({super.key, required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    vehicle.icon,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vehicle.plate,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vehicle.typeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (vehicle.year != null) ...[
                          const Text(
                            ' • ',
                            style: TextStyle(color: AppColors.textHint),
                          ),
                          Text(
                            '${vehicle.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
