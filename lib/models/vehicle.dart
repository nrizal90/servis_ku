enum VehicleType { motor, car }

class Vehicle {
  final int? id;
  final VehicleType vehicleType;
  final String name;
  final String plate;
  final int? year;
  final String? brand;
  final String? imagePath;
  final DateTime? stnkDueDate;
  final DateTime? platDueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    this.id,
    required this.vehicleType,
    required this.name,
    required this.plate,
    this.year,
    this.brand,
    this.imagePath,
    this.stnkDueDate,
    this.platDueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  String get icon => vehicleType == VehicleType.motor ? '🏍️' : '🚗';
  String get typeLabel => vehicleType == VehicleType.motor ? 'Motor' : 'Mobil';

  Vehicle copyWith({
    int? id,
    VehicleType? vehicleType,
    String? name,
    String? plate,
    int? year,
    String? brand,
    String? imagePath,
    DateTime? stnkDueDate,
    DateTime? platDueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleType: vehicleType ?? this.vehicleType,
      name: name ?? this.name,
      plate: plate ?? this.plate,
      year: year ?? this.year,
      brand: brand ?? this.brand,
      imagePath: imagePath ?? this.imagePath,
      stnkDueDate: stnkDueDate ?? this.stnkDueDate,
      platDueDate: platDueDate ?? this.platDueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vehicle_type': vehicleType.name,
      'name': name,
      'plate': plate,
      'year': year,
      'brand': brand,
      'image_path': imagePath,
      'stnk_due_date': stnkDueDate?.toIso8601String().substring(0, 10),
      'plat_due_date': platDueDate?.toIso8601String().substring(0, 10),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name == map['vehicle_type'],
        orElse: () => VehicleType.motor,
      ),
      name: map['name'] as String,
      plate: map['plate'] as String,
      year: map['year'] as int?,
      brand: map['brand'] as String?,
      imagePath: map['image_path'] as String?,
      stnkDueDate: map['stnk_due_date'] != null
          ? DateTime.parse(map['stnk_due_date'] as String)
          : null,
      platDueDate: map['plat_due_date'] != null
          ? DateTime.parse(map['plat_due_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  String toString() =>
      'Vehicle(id: $id, name: $name, plate: $plate, type: ${vehicleType.name})';
}
