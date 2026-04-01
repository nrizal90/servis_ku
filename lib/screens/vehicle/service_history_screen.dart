import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servisku/models/vehicle.dart';
import 'package:servisku/providers/service_record_provider.dart';
import 'package:servisku/screens/vehicle/widgets/history_list.dart';
import 'package:servisku/widgets/confirm_dialog.dart';
import 'package:servisku/widgets/toast.dart';

class ServiceHistoryScreen extends ConsumerWidget {
  final Vehicle vehicle;

  const ServiceHistoryScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsByVehicleProvider(vehicle.id!));

    return Scaffold(
      appBar: AppBar(title: Text('Riwayat Service — ${vehicle.name}')),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada riwayat service.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              HistoryList(
                records: records,
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
                    if (context.mounted) showToast(context, 'Record dihapus');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
