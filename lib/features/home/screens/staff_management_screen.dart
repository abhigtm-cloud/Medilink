import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/services/staff_role_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';

const _roleLabels = {
  'doctor': 'Doctor',
  'ambulance_driver': 'Ambulance Driver',
  'pharmacy': 'Pharmacy Staff',
  'emergency_staff': 'Emergency Staff',
};

const _roleIcons = {
  'doctor': Icons.medical_services_outlined,
  'ambulance_driver': Icons.local_shipping_outlined,
  'pharmacy': Icons.medication_outlined,
  'emergency_staff': Icons.emergency_outlined,
};

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _service = StaffRoleService();
  String _role = StaffRoleService.assignableRoles.first;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit(String hospitalId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final email = _emailController.text.trim();
      await _service.assignStaffRole(
        email: email,
        role: _role,
        hospitalId: hospitalId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $email assigned as ${_roleLabels[_role]}'),
          backgroundColor: Colors.green,
        ),
      );
      _emailController.clear();
      _nameController.clear();
      _tabController.animateTo(0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning role: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hospitalIdAsync = ref.watch(currentHospitalIdProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Manage Hospital Staff'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: 'Staff Roster'),
            Tab(icon: Icon(Icons.person_add_outlined), text: 'Assign Staff'),
          ],
        ),
      ),
      body: hospitalIdAsync.when(
        data: (hospitalId) {
          final targetHospitalId = hospitalId ?? 'general';
          return TabBarView(
            controller: _tabController,
            children: [
              _StaffRosterTab(
                hospitalId: targetHospitalId,
                service: _service,
                onAddTap: () => _tabController.animateTo(1),
              ),
              _AssignStaffTab(
                formKey: _formKey,
                emailController: _emailController,
                nameController: _nameController,
                selectedRole: _role,
                submitting: _submitting,
                onRoleChanged: (role) => setState(() => _role = role),
                onSubmit: () => _submit(targetHospitalId),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _StaffRosterTab extends StatelessWidget {
  const _StaffRosterTab({
    required this.hospitalId,
    required this.service,
    required this.onAddTap,
  });

  final String hospitalId;
  final StaffRoleService service;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StaffMember>>(
      stream: service.watchHospitalStaff(hospitalId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final staff = snapshot.data ?? [];
        if (staff.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge_outlined, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No Staff Assigned Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Assign roles to doctors, drivers, and pharmacists so they can manage hospital operations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onAddTap,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Assign First Staff Member'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: staff.length,
          itemBuilder: (context, index) {
            final member = staff[index];
            final roleLabel = _roleLabels[member.role] ?? member.role;
            final icon = _roleIcons[member.role] ?? Icons.person;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Icon(icon, color: AppColors.primary),
                ),
                title: Text(
                  member.name?.isNotEmpty == true ? member.name! : member.email,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (member.name?.isNotEmpty == true)
                      Text(member.email, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove Staff',
                  onPressed: () async {
                    await service.removeStaffMember(hospitalId, member.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Staff member removed')),
                      );
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AssignStaffTab extends StatelessWidget {
  const _AssignStaffTab({
    required this.formKey,
    required this.emailController,
    required this.nameController,
    required this.selectedRole,
    required this.submitting,
    required this.onRoleChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController nameController;
  final String selectedRole;
  final bool submitting;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Assign staff roles to existing app users. The assigned staff will gain immediate access to their designated tools upon logging in.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Staff Full Name (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Staff Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
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
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Assign Role',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work_outline),
              ),
              items: StaffRoleService.assignableRoles
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Row(
                          children: [
                            Icon(_roleIcons[role] ?? Icons.person, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(_roleLabels[role]!),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) onRoleChanged(value);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: submitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Assign Role to Staff', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
