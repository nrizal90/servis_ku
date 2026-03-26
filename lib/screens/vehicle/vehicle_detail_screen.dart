import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servisku/config/theme.dart';
import 'package:servisku/database/database_helper.dart';
import 'package:servisku/models/fuel_record.dart';
import 'package:servisku/models/service_record.dart';
import 'package:servisku/models/service_type.dart';
import 'package:servisku/models/vehicle.dart';
import 'package:servisku/providers/fuel_record_provider.dart';
import 'package:servisku/providers/service_record_provider.dart';
import 'package:servisku/providers/vehicle_provider.dart';
import 'package:servisku/screens/vehicle/widgets/history_list.dart';
import 'package:servisku/screens/vehicle/widgets/service_status_grid.dart';
import 'package:servisku/services/notification_service.dart';
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

class _DetailView extends ConsumerStatefulWidget {
  final Vehicle vehicle;
  final AsyncValue<List<ServiceRecord>> recordsAsync;

  const _DetailView({required this.vehicle, required this.recordsAsync});

  @override
  ConsumerState<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<_DetailView> {
  String? _filterTypeId;

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit kendaraan',
            onPressed: () => context.push('/edit-vehicle', extra: vehicle),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Hapus kendaraan',
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
      body: widget.recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (records) {
          final filtered = _filterTypeId == null
              ? records
              : records.where((r) => r.serviceType == _filterTypeId).toList();
          final fuelAsync =
              ref.watch(fuelRecordsByVehicleProvider(vehicle.id!));

          return CustomScrollView(
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
                          const SizedBox(height: 16),
                          if (records.isNotEmpty) ...[
                            _StatsSection(records: records),
                            const SizedBox(height: 20),
                          ],
                          const Text(
                            'Status Service',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ServiceStatusGrid(
                              vehicle: vehicle, records: records),
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
                                _FilterDropdown(
                                  vehicleType: vehicle.vehicleType,
                                  selectedId: _filterTypeId,
                                  onChanged: (id) =>
                                      setState(() => _filterTypeId = id),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          HistoryList(
                            records: filtered,
                            onEdit: (r) => context.push(
                              '/vehicle/${vehicle.id}/service/edit',
                              extra: r,
                            ),
                            onDelete: (r) async {
                              final ok = await showConfirmDialog(
                                context,
                                title: 'Hapus Record',
                                message: 'Hapus catatan service ini?',
                              );
                              if (ok && context.mounted) {
                                await ref
                                    .read(serviceRecordProvider.notifier)
                                    .deleteRecord(r.id!);
                                if (context.mounted) {
                                  showToast(context, 'Record dihapus');
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          // ── Section BBM ──
                          const Text(
                            'Konsumsi BBM',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          fuelAsync.when(
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (e, _) =>
                                Text('Error: $e'),
                            data: (fuelRecords) => _FuelSection(
                              fuelRecords: fuelRecords,
                              vehicle: vehicle,
                              onEdit: (r) => context.push(
                                '/vehicle/${vehicle.id}/fuel/edit',
                                extra: r,
                              ),
                              onDelete: (r) async {
                                final ok = await showConfirmDialog(
                                  context,
                                  title: 'Hapus Record BBM',
                                  message: 'Hapus catatan isi BBM ini?',
                                );
                                if (ok && context.mounted) {
                                  await ref
                                      .read(fuelRecordProvider.notifier)
                                      .deleteRecord(r.id!, vehicle.id!);
                                  ref.invalidate(fuelRecordsByVehicleProvider(
                                      vehicle.id!));
                                  if (context.mounted) {
                                    showToast(context, 'Record BBM dihapus');
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _FabButton(
            icon: Icons.local_gas_station_rounded,
            label: 'Catat BBM',
            onPressed: () =>
                context.push('/vehicle/${vehicle.id}/fuel'),
          ),
          const SizedBox(height: 10),
          _FabButton(
            icon: Icons.build_rounded,
            label: 'Catat Service',
            onPressed: () =>
                context.push('/vehicle/${vehicle.id}/service'),
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

// ─── Stats Section ────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final List<ServiceRecord> records;

  const _StatsSection({required this.records});

  @override
  Widget build(BuildContext context) {
    final totalCost = records.fold(0, (s, r) => s + (r.cost ?? 0));
    final lastRecord = records.isNotEmpty ? records.first : null;
    final lastKm = records
        .where((r) => r.km != null)
        .fold<int?>(null,
            (prev, r) => (prev == null || r.km! > prev) ? r.km : prev);

    int avgPerMonth = 0;
    if (records.length > 1) {
      final months =
          records.first.date.difference(records.last.date).inDays / 30;
      if (months > 0) avgPerMonth = (totalCost / months).round();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.button,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(label: 'Total Service', value: '${records.length}x'),
              _StatItem(label: 'Total Biaya', value: formatCurrency(totalCost)),
              _StatItem(
                  label: 'Avg/bulan',
                  value: avgPerMonth > 0 ? formatCurrency(avgPerMonth) : '-'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(
                label: 'Servis Terakhir',
                value: lastRecord != null ? formatDate(lastRecord.date) : '-',
              ),
              _StatItem(
                label: 'Km Terakhir',
                value: lastKm != null ? formatKm(lastKm) : '-',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
        ],
      ),
    );
  }
}

// ─── Filter Dropdown ──────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final VehicleType vehicleType;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.vehicleType,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = getServiceTypesFor(vehicleType);
    return DropdownButton<String?>(
      value: selectedId,
      hint: const Text('Semua',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      underline: const SizedBox.shrink(),
      isDense: true,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Semua', style: TextStyle(fontSize: 12)),
        ),
        ...types.map((st) => DropdownMenuItem<String?>(
              value: st.id,
              child: Text('${st.icon} ${st.label}',
                  style: const TextStyle(fontSize: 12)),
            )),
      ],
      onChanged: onChanged,
    );
  }
}

// ─── Vehicle Banner ───────────────────────────────────────────────────────────

class _VehicleBanner extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleBanner({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final gradient = vehicle.vehicleType == VehicleType.motor
        ? AppColors.gradientMotor
        : AppColors.gradientCar;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          // Large icon with soft white bg
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(vehicle.icon,
                  style: const TextStyle(fontSize: 38)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    vehicle.plate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    vehicle.typeLabel,
                    if (vehicle.year != null) '${vehicle.year}',
                  ].join(' · '),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Admin Section ────────────────────────────────────────────────────────────

class _AdminSection extends StatelessWidget {
  final Vehicle vehicle;
  final WidgetRef ref;

  const _AdminSection({required this.vehicle, required this.ref});

  @override
  Widget build(BuildContext context) {
    final stnkStatus = ServiceCalculator.getStnkStatus(vehicle.stnkDueDate);
    final platStatus = ServiceCalculator.getPlatStatus(vehicle.platDueDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                final updated = vehicle.copyWith(stnkDueDate: newDate);
                await ref.read(vehicleProvider.notifier).updateVehicle(updated);
                await NotificationService.instance.cancelStnkReminders(vehicle);
                await NotificationService.instance.scheduleStnkReminders(updated);
                if (context.mounted) {
                  showToast(context,
                      'STNK diperbarui! Jatuh tempo: ${formatDate(newDate)}');
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
                final updated = vehicle.copyWith(platDueDate: newDate);
                await ref.read(vehicleProvider.notifier).updateVehicle(updated);
                await NotificationService.instance.cancelPlatReminders(vehicle);
                await NotificationService.instance.schedulePlatReminders(updated);
                if (context.mounted) {
                  showToast(context,
                      'Plat diperbarui! Jatuh tempo: ${formatDate(newDate)}');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FAB Button ───────────────────────────────────────────────────────────────

class _FabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _FabButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.button,
        ),
        child: FloatingActionButton.extended(
          heroTag: label,
          onPressed: onPressed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: Icon(icon, color: Colors.white),
          label: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
    }
    return FloatingActionButton.extended(
      heroTag: label,
      onPressed: onPressed,
      backgroundColor: Colors.white,
      elevation: 2,
      icon: Icon(icon, color: AppColors.primary),
      label: Text(label,
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Fuel Section ─────────────────────────────────────────────────────────────

class _FuelSection extends StatelessWidget {
  final List<FuelRecord> fuelRecords;
  final Vehicle vehicle;
  final void Function(FuelRecord) onEdit;
  final void Function(FuelRecord) onDelete;

  const _FuelSection({
    required this.fuelRecords,
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  /// Hitung rata-rata konsumsi (km/liter) dari selisih odometer antar isian
  double? _avgEfficiency() {
    final withKm = fuelRecords
        .where((r) => r.km != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (withKm.length < 2) return null;

    double totalEff = 0;
    int count = 0;
    for (int i = 1; i < withKm.length; i++) {
      final kmDiff = withKm[i].km! - withKm[i - 1].km!;
      if (kmDiff > 0) {
        totalEff += kmDiff / withKm[i].liters;
        count++;
      }
    }
    return count > 0 ? totalEff / count : null;
  }

  @override
  Widget build(BuildContext context) {
    final totalBbmCost =
        fuelRecords.fold(0, (s, r) => s + r.totalCost);
    final totalLiters =
        fuelRecords.fold(0.0, (s, r) => s + r.liters);
    final avgEff = _avgEfficiency();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fuelRecords.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1B6B3A),
              gradient: const LinearGradient(
                colors: [Color(0xFF1B6B3A), Color(0xFF2E9E58)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.button,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ringkasan BBM',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatItem(
                        label: 'Total Isi',
                        value: '${fuelRecords.length}x'),
                    _StatItem(
                        label: 'Total Liter',
                        value:
                            '${totalLiters.toStringAsFixed(1)} L'),
                    _StatItem(
                        label: 'Total Biaya',
                        value: formatCurrency(totalBbmCost)),
                  ],
                ),
                if (avgEff != null) ...[
                  const SizedBox(height: 12),
                  Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatItem(
                        label: 'Rata-rata Konsumsi',
                        value: '${avgEff.toStringAsFixed(1)} km/L',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (fuelRecords.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: const Text(
              'Belum ada catatan BBM',
              style: TextStyle(
                  color: AppColors.textHint, fontSize: 13),
            ),
          )
        else
          ...fuelRecords.map((r) => _FuelTile(
                record: r,
                onEdit: () => onEdit(r),
                onDelete: () => onDelete(r),
              )),
      ],
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
                          fontSize: 12,
                          color: AppColors.textSecondary),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
