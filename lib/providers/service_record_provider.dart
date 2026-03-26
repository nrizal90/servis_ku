import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servisku/database/database_helper.dart';
import 'package:servisku/models/service_record.dart';
import 'package:servisku/utils/service_calculator.dart';
import 'package:servisku/providers/vehicle_provider.dart';

class ServiceRecordNotifier extends AsyncNotifier<List<ServiceRecord>> {
  @override
  Future<List<ServiceRecord>> build() =>
      DatabaseHelper.instance.getAllRecords();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => DatabaseHelper.instance.getAllRecords());
  }

  Future<ServiceRecord> addRecord(ServiceRecord record) async {
    final saved = await DatabaseHelper.instance.insertServiceRecord(record);
    await reload();
    return saved;
  }

  Future<void> deleteRecord(int id) async {
    await DatabaseHelper.instance.deleteServiceRecord(id);
    await reload();
  }
}

final serviceRecordProvider =
    AsyncNotifierProvider<ServiceRecordNotifier, List<ServiceRecord>>(
        ServiceRecordNotifier.new);

final recordsByVehicleProvider =
    Provider.family<AsyncValue<List<ServiceRecord>>, int>((ref, vehicleId) {
  return ref.watch(serviceRecordProvider).whenData(
      (list) => list.where((r) => r.vehicleId == vehicleId).toList());
});

final alertsProvider = Provider<AsyncValue<List<UpcomingAlert>>>((ref) {
  final vehicles = ref.watch(vehicleProvider);
  final records = ref.watch(serviceRecordProvider);

  if (vehicles is AsyncLoading || records is AsyncLoading) {
    return const AsyncLoading();
  }

  return vehicles.whenData((vList) {
    final rList = records.valueOrNull ?? [];
    return ServiceCalculator.getAllAlerts(vList, rList);
  });
});
