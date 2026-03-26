import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servisku/config/theme.dart';
import 'package:servisku/models/vehicle.dart';
import 'package:servisku/providers/vehicle_provider.dart';
import 'package:servisku/providers/service_record_provider.dart';
import 'package:servisku/screens/home/widgets/alert_card.dart';
import 'package:servisku/screens/home/widgets/empty_state.dart';
import 'package:servisku/screens/home/widgets/vehicle_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  VehicleType? _selectedType;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(filteredVehicleProvider(_selectedType));
    final alertsAsync = ref.watch(alertsProvider);

    final filteredAsync = vehiclesAsync.whenData((list) => _searchQuery.isEmpty
        ? list
        : list.where((v) {
            final q = _searchQuery.toLowerCase();
            return v.name.toLowerCase().contains(q) ||
                v.plate.toLowerCase().contains(q);
          }).toList());

    final totalVehicles = vehiclesAsync.valueOrNull?.length ?? 0;
    final totalAlerts = alertsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vehicleProvider);
          ref.invalidate(serviceRecordProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Gradient Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'ServisKu 🔧',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref.invalidate(vehicleProvider);
                            ref.invalidate(serviceRecordProvider);
                          },
                          icon: const Icon(Icons.refresh_rounded,
                              color: Colors.white70, size: 20),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalVehicles kendaraan terdaftar'
                      '${totalAlerts > 0 ? ' · $totalAlerts perlu perhatian' : ''}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau plat nomor…',
                          hintStyle: const TextStyle(
                              color: Colors.white54, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Colors.white54, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: Colors.white54, size: 18),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          fillColor: Colors.transparent,
                          filled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Filter Tabs ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildFilterTabs(),
              ),
            ),

            // ── Alert Section ────────────────────────────────────────────
            alertsAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Perlu Perhatian',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${alerts.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...alerts.map((a) => AlertCard(
                              alert: a,
                              onTap: () =>
                                  context.push('/vehicle/${a.vehicle.id}'),
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── Vehicle List ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              sliver: filteredAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                      child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $e')),
                ),
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return SliverToBoxAdapter(
                      child: EmptyState(
                        message: _searchQuery.isNotEmpty
                            ? 'Kendaraan tidak ditemukan.'
                            : 'Belum ada kendaraan.\nYuk tambah kendaraan pertamamu!',
                        actionLabel:
                            _searchQuery.isEmpty ? '+ Tambah Kendaraan' : null,
                        onAction: _searchQuery.isEmpty
                            ? () => context.push('/add-vehicle')
                            : null,
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        if (i == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.gradientPrimary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Kendaraan Kamu',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              VehicleCard(
                                vehicle: vehicles[0],
                                onTap: () => context
                                    .push('/vehicle/${vehicles[0].id}'),
                              ),
                            ],
                          );
                        }
                        return VehicleCard(
                          vehicle: vehicles[i],
                          onTap: () =>
                              context.push('/vehicle/${vehicles[i].id}'),
                        );
                      },
                      childCount: vehicles.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.button,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/add-vehicle'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Tambah',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      (null, 'Semua'),
      (VehicleType.motor, '🏍️ Motor'),
      (VehicleType.car, '🚗 Mobil'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final selected = _selectedType == tab.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.gradientPrimary : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: selected ? AppShadows.button : AppShadows.card,
                ),
                child: Text(
                  tab.$2,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
