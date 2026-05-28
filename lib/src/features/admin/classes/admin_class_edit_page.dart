import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/admin/classes/application/admin_classes_provider.dart';

/// Create or edit a class.
/// Pass [classData] to open in edit mode; omit for create mode.
class AdminClassEditPage extends ConsumerStatefulWidget {
  const AdminClassEditPage({super.key, this.classData});

  final Map<String, dynamic>? classData;

  @override
  ConsumerState<AdminClassEditPage> createState() => _AdminClassEditPageState();
}

class _AdminClassEditPageState extends ConsumerState<AdminClassEditPage> {
  final _formKey       = GlobalKey<FormState>();
  late final _nameCtrl     = TextEditingController(text: widget.classData?['name']        as String? ?? '');
  late final _gradeCtrl    = TextEditingController(text: widget.classData?['grade_level'] as String? ?? '');
  late final _capacityCtrl = TextEditingController(
    text: ((widget.classData?['capacity'] as num?)?.toInt() ?? 40).toString(),
  );

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.classData != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gradeCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    try {
      final repo     = ref.read(classesApiRepositoryProvider);
      final name     = _nameCtrl.text.trim();
      final grade    = _gradeCtrl.text.trim();
      final capacity = int.tryParse(_capacityCtrl.text.trim()) ?? 40;

      if (_isEdit) {
        await repo.updateClass(
          id:         widget.classData!['id'] as int,
          name:       name,
          gradeLevel: grade,
          capacity:   capacity,
        );
      } else {
        await repo.createClass(name: name, gradeLevel: grade, capacity: capacity);
      }

      ref.invalidate(adminClassesProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Class' : 'New Class'),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: TextStyle(color: cs.onErrorContainer)),
                ),

              _field(
                controller: _nameCtrl,
                label: 'Class Name',
                hint: 'e.g.  10A  or  Grade 9 Red',
                icon: Icons.school_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Class name is required' : null,
              ),
              const SizedBox(height: 16),

              _field(
                controller: _gradeCtrl,
                label: 'Grade Level',
                hint: 'e.g.  Grade 10  or  Grade 9',
                icon: Icons.grade_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Grade level is required' : null,
              ),
              const SizedBox(height: 16),

              _field(
                controller: _capacityCtrl,
                label: 'Capacity',
                hint: 'Max students in this class',
                icon: Icons.people_outline,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEdit ? 'Save Changes' : 'Create Class',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error),
        ),
      ),
    );
  }
}
