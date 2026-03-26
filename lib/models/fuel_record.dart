class FuelRecord {
  final int? id;
  final int vehicleId;
  final DateTime date;
  final int? km;
  final double liters;
  final int? pricePerLiter;
  final int totalCost;
  final String? fuelType;
  final String? notes;
  final DateTime createdAt;

  const FuelRecord({
    this.id,
    required this.vehicleId,
    required this.date,
    this.km,
    required this.liters,
    this.pricePerLiter,
    required this.totalCost,
    this.fuelType,
    this.notes,
    required this.createdAt,
  });

  FuelRecord copyWith({
    int? id,
    int? vehicleId,
    DateTime? date,
    int? km,
    double? liters,
    int? pricePerLiter,
    int? totalCost,
    String? fuelType,
    String? notes,
    DateTime? createdAt,
  }) {
    return FuelRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      km: km ?? this.km,
      liters: liters ?? this.liters,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      totalCost: totalCost ?? this.totalCost,
      fuelType: fuelType ?? this.fuelType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vehicle_id': vehicleId,
      'date': date.toIso8601String().substring(0, 10),
      'km': km,
      'liters': liters,
      'price_per_liter': pricePerLiter,
      'total_cost': totalCost,
      'fuel_type': fuelType,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FuelRecord.fromMap(Map<String, dynamic> map) {
    return FuelRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      date: DateTime.parse(map['date'] as String),
      km: map['km'] as int?,
      liters: (map['liters'] as num).toDouble(),
      pricePerLiter: map['price_per_liter'] as int?,
      totalCost: map['total_cost'] as int,
      fuelType: map['fuel_type'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() =>
      'FuelRecord(id: $id, vehicleId: $vehicleId, date: $date, liters: $liters)';
}
