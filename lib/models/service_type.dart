import 'package:servisku/models/vehicle.dart';

class ServiceType {
  final String id;
  final String label;
  final String icon;
  final int? intervalKm;
  final int? intervalDays;
  final List<VehicleType> appliesTo;

  const ServiceType({
    required this.id,
    required this.label,
    required this.icon,
    this.intervalKm,
    this.intervalDays,
    required this.appliesTo,
  });
}

const List<ServiceType> defaultServiceTypes = [
  // === UMUM (motor & mobil) ===
  ServiceType(id: 'tire',      label: 'Cek Ban',       icon: '🔘', intervalKm: 10000, intervalDays: 180,  appliesTo: [VehicleType.motor, VehicleType.car]),
  ServiceType(id: 'brake',     label: 'Rem',           icon: '🛑', intervalKm: 15000, intervalDays: 365,  appliesTo: [VehicleType.motor, VehicleType.car]),
  ServiceType(id: 'coolant',   label: 'Coolant',       icon: '❄️', intervalKm: 20000, intervalDays: 365,  appliesTo: [VehicleType.motor, VehicleType.car]),
  ServiceType(id: 'filter',    label: 'Filter Udara',  icon: '🌬️', intervalKm: 15000, intervalDays: 365,  appliesTo: [VehicleType.motor, VehicleType.car]),

  // === KHUSUS MOTOR ===
  ServiceType(id: 'oil_motor', label: 'Ganti Oli',     icon: '🛢️', intervalKm: 3000,  intervalDays: 90,   appliesTo: [VehicleType.motor]),
  ServiceType(id: 'spark',     label: 'Busi',          icon: '⚡', intervalKm: 8000,  intervalDays: 180,  appliesTo: [VehicleType.motor]),
  ServiceType(id: 'chain',     label: 'Rantai',        icon: '🔗', intervalKm: 5000,  intervalDays: 120,  appliesTo: [VehicleType.motor]),
  ServiceType(id: 'cvt',       label: 'CVT / V-Belt',  icon: '⚙️', intervalKm: 20000, intervalDays: 365,  appliesTo: [VehicleType.motor]),

  // === KHUSUS MOBIL ===
  ServiceType(id: 'oil_trans', label: 'Oli Transmisi', icon: '⚙️', intervalKm: 40000, intervalDays: 730,  appliesTo: [VehicleType.car]),
  ServiceType(id: 'ac',        label: 'Service AC',    icon: '🌡️', intervalKm: 20000, intervalDays: 365,  appliesTo: [VehicleType.car]),
  ServiceType(id: 'sparkplug', label: 'Busi',          icon: '⚡', intervalKm: 20000, intervalDays: 365,  appliesTo: [VehicleType.car]),
  ServiceType(id: 'timing',    label: 'Timing Belt',   icon: '🔄', intervalKm: 80000, intervalDays: 1460, appliesTo: [VehicleType.car]),
  ServiceType(id: 'battery',   label: 'Aki / Baterai', icon: '🔋', intervalKm: null,  intervalDays: 730,  appliesTo: [VehicleType.car]),
  ServiceType(id: 'wiper',     label: 'Wiper',         icon: '🌧️', intervalKm: null,  intervalDays: 365,  appliesTo: [VehicleType.car]),

  // === LAINNYA ===
  ServiceType(id: 'other',     label: 'Lainnya',       icon: '🔧', intervalKm: null,  intervalDays: null, appliesTo: [VehicleType.motor, VehicleType.car]),
];

List<ServiceType> getServiceTypesFor(VehicleType type) {
  return defaultServiceTypes
      .where((st) => st.appliesTo.contains(type))
      .toList();
}
