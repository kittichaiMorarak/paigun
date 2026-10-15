import 'package:flutter/material.dart';
import '../models/place.dart';
import '../services/app_state.dart';

const regionsList = ['เหนือ', 'กลาง', 'ตะวันออก', 'ตะวันตก', 'อีสาน', 'ใต้'];

const categoriesList = [
  {'key': 'temple', 'label': 'วัด/ศาสนสถาน'},
  {'key': 'nature', 'label': 'ธรรมชาติ'},
  {'key': 'beach', 'label': 'ทะเล/หาด'},
  {'key': 'history', 'label': 'ประวัติศาสตร์'},
  {'key': 'market', 'label': 'ตลาด/ช้อปปิ้ง'},
  {'key': 'cafe', 'label': 'คาเฟ่'},
];

class AddPlaceDialog extends StatefulWidget {
  const AddPlaceDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const AddPlaceDialog(),
    );
  }

  @override
  State<AddPlaceDialog> createState() => _AddPlaceDialogState();
}

class _AddPlaceDialogState extends State<AddPlaceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _provinceController = TextEditingController();
  final _descController = TextEditingController();
  final _feeController = TextEditingController();
  final _durationController = TextEditingController(text: '90');
  final _latController = TextEditingController(text: '13.7563');
  final _lngController = TextEditingController(text: '100.5018');

  String _region = 'กลาง';
  String _category = 'nature';

  @override
  void dispose() {
    _nameController.dispose();
    _provinceController.dispose();
    _descController.dispose();
    _feeController.dispose();
    _durationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final appState = AppStateProvider.of(context);
    final newId = DateTime.now().millisecondsSinceEpoch % 100000;

    final newPlace = Place(
      id: newId,
      name: _nameController.text.trim(),
      province: _provinceController.text.trim(),
      region: _region,
      category: _category,
      lat: double.tryParse(_latController.text.trim()) ?? 13.75,
      lng: double.tryParse(_lngController.text.trim()) ?? 100.50,
      avgDurationMin: int.tryParse(_durationController.text.trim()) ?? 90,
      open: '08:00',
      close: '17:00',
      fee: _feeController.text.trim().isNotEmpty
          ? _feeController.text.trim()
          : 'ฟรี',
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : 'สถานที่ท่องเที่ยวแนะนำ',
      verified: true,
    );

    appState.addCustomPlace(newPlace);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เพิ่มสถานที่ "${newPlace.name}" สำเร็จแล้ว')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_location_alt_outlined, color: Color(0xFF1F6247)),
          SizedBox(width: 8),
          Text('เพิ่มสถานที่เที่ยวใหม่'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อสถานที่ *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _provinceController,
                decoration: const InputDecoration(
                  labelText: 'จังหวัด *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'กรุณากรอกจังหวัด' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _region,
                      decoration: const InputDecoration(
                        labelText: 'ภาค',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: regionsList
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) => setState(() => _region = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'หมวดหมู่',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: categoriesList
                          .map((c) => DropdownMenuItem(
                                value: c['key'],
                                child: Text(c['label']!),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'คำอธิบายสถานที่',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _feeController,
                      decoration: const InputDecoration(
                        labelText: 'ค่าเข้าชม (บาท)',
                        hintText: 'ฟรี หรือ 100',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'เวลานาที (~)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F6247),
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: const Text('บันทึกสถานที่'),
        ),
      ],
    );
  }
}
