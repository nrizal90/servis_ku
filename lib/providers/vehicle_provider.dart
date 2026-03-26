import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servisku/database/database_helper.dart';
import 'package:servisku/models/vehicle.dart';

class VehicleNotifier extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() => DatabaseHelper.instance.getAllVehicles();

  Future<void> loadVehicles() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => DatabaseHelper.instance.getAllVehicles());
  }

  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    final saved = await DatabaseHelper.instance.insertVehicle(vehicle);
    await loadVehicles();
    return saved;
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await DatabaseHelper.instance.updateVehicle(vehicle);
    await loadVehicles();
  }

  Future<void> deleteVehicle(int id) async {
    await DatabaseHelper.instance.deleteVehicle(id);
    await loadVehicles();
  }
}

final vehicleProvider =
    AsyncNotifierProvider<VehicleNotifier, List<Vehicle>>(VehicleNotifier.new);

final filteredVehicleProvider =
    Provider.family<AsyncValue<List<Vehicle>>, VehicleType?>((ref, type) {
  final vehicles = ref.watch(vehicleProvider);
  if (type == null) return vehicles;
  return vehicles.whenData(
      (list) => list.where((v) => v.vehicleType == type).toList());
});
