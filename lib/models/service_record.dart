class ServiceRecord {
  final int? id;
  final int vehicleId;
  final String serviceType;
  final DateTime date;
  final int? km;
  final int? cost;
  final String? notes;
  final String? bengkel;
  final DateTime createdAt;

  const ServiceRecord({
    this.id,
    required this.vehicleId,
    required this.serviceType,
    required this.date,
    this.km,
    this.cost,
    this.notes,
    this.bengkel,
    required this.createdAt,
  });

  ServiceRecord copyWith({
    int? id,
    int? vehicleId,
    String? serviceType,
    DateTime? date,
    int? km,
    int? cost,
    String? notes,
    String? bengkel,
    DateTime? createdAt,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      serviceType: serviceType ?? this.serviceType,
      date: date ?? this.date,
      km: km ?? this.km,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      bengkel: bengkel ?? this.bengkel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vehicle_id': vehicleId,
      'service_type': serviceType,
      'date': date.toIso8601String().substring(0, 10),
      'km': km,
      'cost': cost,
      'notes': notes,
      'bengkel': bengkel,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    return ServiceRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      serviceType: map['service_type'] as String,
      date: DateTime.parse(map['date'] as String),
      km: map['km'] as int?,
      cost: map['cost'] as int?,
      notes: map['notes'] as String?,
      bengkel: map['bengkel'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() =>
      'ServiceRecord(id: $id, vehicleId: $vehicleId, type: $serviceType, date: $date)';
}
