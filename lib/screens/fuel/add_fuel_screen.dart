import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servisku/config/theme.dart';
import 'package:servisku/database/database_helper.dart';
import 'package:servisku/models/fuel_record.dart';
import 'package:servisku/models/vehicle.dart';
import 'package:servisku/providers/fuel_record_provider.dart';
import 'package:servisku/utils/format_utils.dart';
import 'package:servisku/widgets/app_button.dart';
import 'package:servisku/widgets/app_input.dart';
import 'package:servisku/widgets/toast.dart';

const _fuelTypes = ['Pertalite', 'Pertamax Green 92', 'Pertamax', 'Pertamax Turbo', 'Solar', 'Dexlite', 'Pertamina Dex', 'Shell Super', 'Shell V-Power', 'Shell V-Power Nitro+', 'Shell V-Power Diesel', 'Total Performance 92', 'Total Performance 95', 'Revvo 89', 'Revvo 92', 'Revvo 95', 'BP 90', 'BP 95', 'BP Diesel', 'Lainnya...'];

class AddFuelScreen extends ConsumerStatefulWidget {
  final int vehicleId;
  final FuelRecord? existingRecord;

  const AddFuelScreen({
    super.key,
    required this.vehicleId,
    this.existingRecord,
  });

  @override
  ConsumerState<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends ConsumerState<AddFuelScreen> {
  final _kmCtrl = TextEditingController();
  final _litersCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Vehicle? _vehicle;
  late DateTime _date;
  String? _selectedFuelType;
  bool _saving = false;

  bool get _isEdit => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existingRecord;
    _date = r?.date ?? DateTime.now();
    _selectedFuelType = r?.fuelType ?? _fuelTypes.first;
    _kmCtrl.text = r?.km?.toString() ?? '';
    _litersCtrl.text = r?.liters.toString() ?? '';
    _priceCtrl.text = r?.pricePerLiter?.toString() ?? '';
    _totalCtrl.text = r?.totalCost.toString() ?? '';
    _notesCtrl.text = r?.notes ?? '';

    DatabaseHelper.instance
        .getVehicleById(widget.vehicleId)
        .then((v) => setState(() => _vehicle = v));

    _litersCtrl.addListener(_autoCalcTotal);
    _priceCtrl.addListener(_autoCalcTotal);
  }

  @override
  void dispose() {
    _litersCtrl.removeListener(_autoCalcTotal);
    _priceCtrl.removeListener(_autoCalcTotal);
    _kmCtrl.dispose();
    _litersCtrl.dispose();
    _priceCtrl.dispose();
    _totalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Hitung total otomatis dari liter × harga/liter
  void _autoCalcTotal() {
    final liters = double.tryParse(_litersCtrl.text);
    final price = int.tryParse(_priceCtrl.text);
    if (liters != null && price != null) {
      final total = (liters * price).round();
      final newText = total.toString();
      if (_totalCtrl.text != newText) {
        _totalCtrl.text = newText;
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final liters = double.tryParse(_litersCtrl.text);
    final total = int.tryParse(_totalCtrl.text);

    if (liters == null || liters <= 0) {
      showToast(context, 'Isi jumlah liter dulu', isError: true);
      return;
    }
    if (total == null || total <= 0) {
      showToast(context, 'Isi total biaya dulu', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final updated = widget.existingRecord!.copyWith(
          date: _date,
          km: _kmCtrl.text.isNotEmpty ? int.tryParse(_kmCtrl.text) : null,
          liters: liters,
          pricePerLiter:
              _priceCtrl.text.isNotEmpty ? int.tryParse(_priceCtrl.text) : null,
          totalCost: total,
          fuelType: _selectedFuelType,
          notes:
              _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        );
        await ref.read(fuelRecordProvider.notifier).updateRecord(updated);
      } else {
        final record = FuelRecord(
          vehicleId: widget.vehicleId,
          date: _date,
          km: _kmCtrl.text.isNotEmpty ? int.tryParse(_kmCtrl.text) : null,
          liters: liters,
          pricePerLiter:
              _priceCtrl.text.isNotEmpty ? int.tryParse(_priceCtrl.text) : null,
          totalCost: total,
          fuelType: _selectedFuelType,
          notes:
              _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
          createdAt: DateTime.now(),
        );
        await ref.read(fuelRecordProvider.notifier).addRecord(record);
      }

      if (mounted) {
        showToast(context,
            _isEdit ? 'BBM berhasil diupdate!' : 'BBM berhasil dicatat!');
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
    if (_vehicle == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Isi BBM' : 'Catat Isi BBM')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header kendaraan
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Text(_vehicle!.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vehicle!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _vehicle!.plate,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tanggal
          GestureDetector(
            onTap: _pickDate,
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
                  const Icon(Icons.calendar_month_rounded,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal Isi BBM',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        formatDate(_date),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Jenis BBM
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFuelType,
                isExpanded: true,
                hint: const Text('Pilih jenis BBM'),
                items: _fuelTypes
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedFuelType = v),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Odometer
          AppInput(
            label: 'Odometer (km)',
            hint: 'cth: 15320',
            controller: _kmCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 14),

          // Liter & Harga per liter
          Row(
            children: [
              Expanded(
                child: AppInput(
                  label: 'Jumlah Liter *',
                  hint: 'cth: 5.5',
                  controller: _litersCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInput(
                  label: 'Harga/Liter (Rp)',
                  hint: 'cth: 10000',
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total biaya
          AppInput(
            label: 'Total Biaya (Rp) *',
            hint: 'Terisi otomatis atau isi manual',
            controller: _totalCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 14),

          AppInput(
            label: 'Catatan',
            hint: 'Catatan tambahan...',
            controller: _notesCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 30),

          AppButton(
            label: _isEdit ? 'Update' : 'Simpan',
            onPressed: _save,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}
