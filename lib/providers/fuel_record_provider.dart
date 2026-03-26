import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servisku/database/database_helper.dart';
import 'package:servisku/models/fuel_record.dart';

class FuelRecordNotifier extends AsyncNotifier<List<FuelRecord>> {
  @override
  Future<List<FuelRecord>> build() async => [];

  Future<void> loadByVehicle(int vehicleId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => DatabaseHelper.instance.getFuelRecordsByVehicle(vehicleId));
  }

  Future<FuelRecord> addRecord(FuelRecord record) async {
    final saved = await DatabaseHelper.instance.insertFuelRecord(record);
    await loadByVehicle(record.vehicleId);
    return saved;
  }

  Future<void> updateRecord(FuelRecord record) async {
    await DatabaseHelper.instance.updateFuelRecord(record);
    await loadByVehicle(record.vehicleId);
  }

  Future<void> deleteRecord(int id, int vehicleId) async {
    await DatabaseHelper.instance.deleteFuelRecord(id);
    await loadByVehicle(vehicleId);
  }
}

final fuelRecordProvider =
    AsyncNotifierProvider<FuelRecordNotifier, List<FuelRecord>>(
        FuelRecordNotifier.new);

final fuelRecordsByVehicleProvider =
    FutureProvider.family<List<FuelRecord>, int>((ref, vehicleId) {
  return DatabaseHelper.instance.getFuelRecordsByVehicle(vehicleId);
});
