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

    // Apply search filter
    final filteredAsync = vehiclesAsync.whenData((list) => _searchQuery.isEmpty
        ? list
        : list.where((v) {
            final q = _searchQuery.toLowerCase();
            return v.name.toLowerCase().contains(q) ||
                v.plate.toLowerCase().contains(q);
          }).toList());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ServisKu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(vehicleProvider);
              ref.invalidate(serviceRecordProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vehicleProvider);
          ref.invalidate(serviceRecordProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Cari kendaraan...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textHint),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 18, color: AppColors.textHint),
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFilterTabs(),
                  ],
                ),
              ),
            ),
            alertsAsync.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Perlu Perhatian',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: filteredAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $e')),
                ),
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return SliverToBoxAdapter(
                      child: EmptyState(
                        message:
                            'Belum ada kendaraan.\nTambahkan kendaraan pertamamu!',
                        actionLabel: '+ Tambah Kendaraan',
                        onAction: () => context.push('/add-vehicle'),
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
                              const Text(
                                'Kendaraan Kamu',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-vehicle'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kendaraan'),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      (null, 'Semua'),
      (VehicleType.motor, '🏍️ Motor'),
      (VehicleType.car, '🚗 Mobil'),
    ];

    return Row(
      children: tabs.map((tab) {
        final selected = _selectedType == tab.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = tab.$1),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                tab.$2,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
