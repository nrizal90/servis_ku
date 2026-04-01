import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servisku/config/theme.dart';
import 'package:servisku/models/fuel_record.dart';
import 'package:servisku/models/vehicle.dart';
import 'package:servisku/providers/fuel_record_provider.dart';
import 'package:servisku/utils/format_utils.dart';
import 'package:servisku/widgets/confirm_dialog.dart';
import 'package:servisku/widgets/toast.dart';

class FuelHistoryScreen extends ConsumerWidget {
  final Vehicle vehicle;

  const FuelHistoryScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelAsync = ref.watch(fuelRecordsByVehicleProvider(vehicle.id!));

    return Scaffold(
      appBar: AppBar(title: Text('Riwayat BBM — ${vehicle.name}')),
      body: fuelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada catatan BBM.',
                style: TextStyle(color: AppColors.textHint),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (ctx, i) {
              final r = records[i];
              return _FuelTile(
                record: r,
                onEdit: () => context.push(
                  '/vehicle/${vehicle.id}/fuel/edit',
                  extra: r,
                ),
                onDelete: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Hapus Record BBM',
                    message: 'Hapus catatan isi BBM ini?',
                  );
                  if (ok && context.mounted) {
                    await ref
                        .read(fuelRecordProvider.notifier)
                        .deleteRecord(r.id!, vehicle.id!);
                    ref.invalidate(fuelRecordsByVehicleProvider(vehicle.id!));
                    if (context.mounted) showToast(context, 'Record BBM dihapus');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _FuelTile extends StatelessWidget {
  final FuelRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FuelTile({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2E9E58).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('⛽', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      record.fuelType ?? 'BBM',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${record.liters.toStringAsFixed(1)} L',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  formatDate(record.date),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (record.km != null)
                  Text(
                    formatKm(record.km!),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(record.totalCost),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: const Text('Edit',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Text('Hapus',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
