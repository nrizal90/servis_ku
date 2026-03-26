import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servisku/config/theme.dart';
import 'package:servisku/database/database_helper.dart';
import 'package:servisku/models/vehicle.dart';
import 'package:servisku/providers/service_record_provider.dart';
import 'package:servisku/providers/vehicle_provider.dart';
import 'package:servisku/screens/vehicle/widgets/history_list.dart';
import 'package:servisku/screens/vehicle/widgets/service_status_grid.dart';
import 'package:servisku/utils/format_utils.dart';
import 'package:servisku/utils/service_calculator.dart';
import 'package:servisku/widgets/confirm_dialog.dart';
import 'package:servisku/widgets/toast.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final int vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsByVehicleProvider(vehicleId));

    return FutureBuilder<Vehicle?>(
      future: DatabaseHelper.instance.getVehicleById(vehicleId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final vehicle = snap.data!;
        return _DetailView(vehicle: vehicle, recordsAsync: recordsAsync);
      },
    );
  }
}

class _DetailView extends ConsumerWidget {
  final Vehicle vehicle;
  final AsyncValue recordsAsync;

  const _DetailView({required this.vehicle, required this.recordsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final ok = await showConfirmDialog(
                context,
                title: 'Hapus Kendaraan',
                message:
                    'Hapus "${vehicle.name}"? Semua riwayat service juga akan dihapus.',
              );
              if (ok && context.mounted) {
                await ref
                    .read(vehicleProvider.notifier)
                    .deleteVehicle(vehicle.id!);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (records) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VehicleBanner(vehicle: vehicle),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AdminSection(vehicle: vehicle, ref: ref),
                        const SizedBox(height: 20),
                        const Text(
                          'Status Service',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ServiceStatusGrid(vehicle: vehicle, records: records),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Riwayat Service',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (records.isNotEmpty)
                              Text(
                                'Total: ${formatCurrency(records.fold(0, (s, r) => s + (r.cost ?? 0)))}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        HistoryList(
                          records: records,
                          onDelete: (r) async {
                            final ok = await showConfirmDialog(
                              context,
                              title: 'Hapus Record',
                              message: 'Hapus catatan service ini?',
                            );
                            if (ok) {
                              await ref
                                  .read(serviceRecordProvider.notifier)
                                  .deleteRecord(r.id!);
                            }
                          },
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vehicle/${vehicle.id}/service'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat Service'),
      ),
    );
  }
}

class _VehicleBanner extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleBanner({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Text(vehicle.icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    vehicle.plate,
                    vehicle.typeLabel,
                    if (vehicle.year != null) '${vehicle.year}',
                  ].join(' · '),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
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

class _AdminSection extends StatelessWidget {
  final Vehicle vehicle;
  final WidgetRef ref;

  const _AdminSection({required this.vehicle, required this.ref});

  @override
  Widget build(BuildContext context) {
    final stnkStatus = ServiceCalculator.getStnkStatus(vehicle.stnkDueDate);
    final platStatus = ServiceCalculator.getPlatStatus(vehicle.platDueDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pajak & Administrasi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _AdminRow(
              icon: '📋',
              label: 'Pajak STNK',
              dueDate: vehicle.stnkDueDate,
              status: stnkStatus,
              actionLabel: 'Sudah Bayar Pajak',
              onAction: () async {
                final newDate = vehicle.stnkDueDate != null
                    ? DateTime(vehicle.stnkDueDate!.year + 1,
                        vehicle.stnkDueDate!.month, vehicle.stnkDueDate!.day)
                    : DateTime.now().add(const Duration(days: 365));
                await ref.read(vehicleProvider.notifier).updateVehicle(
                    vehicle.copyWith(stnkDueDate: newDate));
                if (context.mounted) {
                  showToast(context, 'Tanggal STNK diperbarui');
                }
              },
            ),
            const Divider(height: 20),
            _AdminRow(
              icon: '🔖',
              label: 'Ganti Plat',
              dueDate: vehicle.platDueDate,
              status: platStatus,
              actionLabel: 'Sudah Ganti Plat',
              onAction: () async {
                final newDate = vehicle.platDueDate != null
                    ? DateTime(vehicle.platDueDate!.year + 5,
                        vehicle.platDueDate!.month, vehicle.platDueDate!.day)
                    : DateTime.now().add(const Duration(days: 365 * 5));
                await ref.read(vehicleProvider.notifier).updateVehicle(
                    vehicle.copyWith(platDueDate: newDate));
                if (context.mounted) {
                  showToast(context, 'Tanggal ganti plat diperbarui');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminRow extends StatelessWidget {
  final String icon;
  final String label;
  final DateTime? dueDate;
  final ServiceStatus status;
  final String actionLabel;
  final VoidCallback onAction;

  const _AdminRow({
    required this.icon,
    required this.label,
    required this.dueDate,
    required this.status,
    required this.actionLabel,
    required this.onAction,
  });

  Color get _statusColor {
    if (status.isOverdue) return AppColors.danger;
    if (status.isSoon) return AppColors.warning;
    if (status.isOk) return AppColors.success;
    return AppColors.textHint;
  }

  String get _statusLabel {
    if (status.isUnknown) return 'Belum diset';
    final d = status.daysLeft!;
    if (d < 0) return 'Terlambat ${d.abs()} hari';
    if (d == 0) return 'Hari ini!';
    return '$d hari lagi';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(
                dueDate != null ? formatDate(dueDate!) : '-',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
