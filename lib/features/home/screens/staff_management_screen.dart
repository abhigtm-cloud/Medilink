import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:medilink/core/services/staff_role_service.dart';
import 'package:medilink/core/theme/app_colors.dart';

const _roleLabels = {
  'doctor': 'Doctor',
  'ambulance_driver': 'Ambulance Driver',
  'pharmacy': 'Pharmacy Staff',
  'emergency_staff': 'Emergency Staff',
};

/// Lets a hospital_admin grant a staff role to a user who has already
/// signed up in the app (by email). Server-validated end to end via the
/// `assignStaffRole` Callable Function — see architecture doc §3 and §20
/// (`StaffManagementScreen` in the documented screen list).
class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _service = StaffRoleService();
  String _role = StaffRoleService.assignableRoles.first;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await _service.assignStaffRole(email: _emailController.text.trim(), role: _role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_emailController.text.trim()} is now ${_roleLabels[_role]}'),
        ),
      );
      _emailController.clear();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Failed to assign role')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(title: const Text('Manage Staff')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grant a staff role to a user who has already signed up in '
                'MediLink. They\'ll need to reopen the app (or sign in again) '
                'to pick it up.',
                style: TextStyle(color: AppColors.getTextSecondary(context)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Staff member\'s email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: StaffRoleService.assignableRoles
                    .map((role) => DropdownMenuItem(value: role, child: Text(_roleLabels[role]!)))
                    .toList(),
                onChanged: (value) => setState(() => _role = value!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Assign Role'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
