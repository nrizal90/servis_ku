import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servisku/config/theme.dart';
import 'package:servisku/models/vehicle.dart';
import 'package:servisku/providers/vehicle_provider.dart';
import 'package:servisku/utils/format_utils.dart';
import 'package:servisku/widgets/app_button.dart';
import 'package:servisku/widgets/app_input.dart';
import 'package:servisku/widgets/toast.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();

  VehicleType _selectedType = VehicleType.motor;
  DateTime? _stnkDueDate;
  DateTime? _platDueDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _plateCtrl.dispose();
    _yearCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose();
  }

  String get _namePlaceholder =>
      _selectedType == VehicleType.motor
          ? 'cth: Honda Beat 2022'
          : 'cth: Toyota Avanza 2020';

  Future<void> _pickDate({required bool isStnk}) async {
    final initial = isStnk
        ? (_stnkDueDate ?? DateTime.now())
        : (_platDueDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked == null) return;
    setState(() {
      if (isStnk) {
        _stnkDueDate = picked;
      } else {
        _platDueDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final vehicle = Vehicle(
      vehicleType: _selectedType,
      name: _nameCtrl.text.trim(),
      plate: _plateCtrl.text.trim().toUpperCase(),
      year: _yearCtrl.text.isNotEmpty ? int.tryParse(_yearCtrl.text) : null,
      brand: _brandCtrl.text.trim().isNotEmpty ? _brandCtrl.text.trim() : null,
      stnkDueDate: _stnkDueDate,
      platDueDate: _platDueDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(vehicleProvider.notifier).addVehicle(vehicle);
      if (mounted) {
        showToast(context, 'Kendaraan berhasil ditambahkan!');
        context.pop();
      }
    } catch (e) {
      if (mounted) showToast(context, 'Gagal menyimpan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Kendaraan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Jenis Kendaraan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _TypeButton(
                  icon: '🏍️',
                  label: 'Motor',
                  selected: _selectedType == VehicleType.motor,
                  onTap: () =>
                      setState(() => _selectedType = VehicleType.motor),
                ),
                const SizedBox(width: 12),
                _TypeButton(
                  icon: '🚗',
                  label: 'Mobil',
                  selected: _selectedType == VehicleType.car,
                  onTap: () =>
                      setState(() => _selectedType = VehicleType.car),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppInput(
              label: 'Nama Kendaraan *',
              hint: _namePlaceholder,
              controller: _nameCtrl,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            AppInput(
              label: 'Plat Nomor *',
              hint: 'cth: B 1234 XYZ',
              controller: _plateCtrl,
              inputFormatters: [UpperCaseTextFormatter()],
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    label: 'Tahun',
                    hint: 'cth: 2022',
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppInput(
                    label: 'Merk',
                    hint: 'cth: Honda',
                    controller: _brandCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Pajak & Administrasi',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _DatePickerField(
              label: 'Jatuh Tempo Pajak STNK',
              hint: 'Pilih tanggal jatuh tempo STNK tahunan',
              value: _stnkDueDate,
              onTap: () => _pickDate(isStnk: true),
              onClear: () => setState(() => _stnkDueDate = null),
            ),
            const SizedBox(height: 14),
            _DatePickerField(
              label: 'Jatuh Tempo Ganti Plat (5 Tahun)',
              hint: 'Pilih tanggal jatuh tempo ganti plat nomor',
              value: _platDueDate,
              onTap: () => _pickDate(isStnk: false),
              onClear: () => setState(() => _platDueDate = null),
            ),
            const SizedBox(height: 30),
            AppButton(
              label: 'Simpan',
              onPressed: _save,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String hint;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DatePickerField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != null ? formatDate(value!) : hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textHint),
              )
            else
              const Icon(Icons.calendar_month_rounded,
                  size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
