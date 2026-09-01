import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_theme.dart';
import 'package:medilink/features/auth/models/app_user.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/home/screens/notifications_screen.dart';
import 'package:medilink/features/home/screens/change_password_screen.dart';
import 'package:medilink/features/home/screens/help_support_screen.dart';
import 'package:medilink/features/home/screens/about_medilink_screen.dart';

/// Clinical-grade Patient Profile and Account Management screen.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;
  late TextEditingController _medicationsController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _emergencyRelationController;

  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _photoBase64;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _initialized = false;

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _addressController = TextEditingController();
    _allergiesController = TextEditingController();
    _conditionsController = TextEditingController();
    _medicationsController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _emergencyRelationController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    super.dispose();
  }

  void _populateUserData(AppUser user) {
    if (_initialized && _isEditing) return;

    _nameController.text = user.displayName ?? '';
    _phoneController.text = user.phoneNumber ?? '';
    _dobController.text = user.dateOfBirth ?? '';
    _addressController.text = user.address ?? '';
    _allergiesController.text = user.allergies ?? '';
    _conditionsController.text = user.medicalConditions ?? '';
    _medicationsController.text = user.currentMedications ?? '';
    _emergencyNameController.text = user.emergencyContactName ?? '';
    _emergencyPhoneController.text = user.emergencyContactPhone ?? '';
    _emergencyRelationController.text = user.emergencyContactRelation ?? '';

    _selectedGender = user.gender;
    _selectedBloodGroup = user.bloodGroup;
    _photoBase64 = user.photoUrl;
    _initialized = true;
  }

  Future<void> _pickPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _photoBase64 = base64Encode(bytes);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo selected. Click Save to apply changes.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select photo: $e')),
        );
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    if (!_isEditing) return;
    DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 25));
    if (_dobController.text.isNotEmpty) {
      final parts = _dobController.text.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          initial = DateTime(y, m, d);
        }
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _saveProfile(AppUser currentUser) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final updatedUser = currentUser.copyWith(
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        gender: _selectedGender,
        bloodGroup: _selectedBloodGroup,
        address: _addressController.text.trim(),
        allergies: _allergiesController.text.trim(),
        medicalConditions: _conditionsController.text.trim(),
        currentMedications: _medicationsController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim(),
        emergencyContactRelation: _emergencyRelationController.text.trim(),
        photoUrl: _photoBase64,
      );

      final userRepo = ref.read(userProfileRepositoryProvider);
      await userRepo.updateUserProfile(updatedUser);

      // Refresh auth state to sync with Riverpod listeners
      ref.invalidate(authStateChangesProvider);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Patient profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 1,
        title: const Text(
          'Patient Health Profile',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          authState.maybeWhen(
            data: (user) => user == null
                ? const SizedBox.shrink()
                : TextButton.icon(
                    icon: Icon(_isEditing ? Icons.close : Icons.edit, size: 18),
                    label: Text(_isEditing ? 'Cancel' : 'Edit'),
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() {
                              if (_isEditing) {
                                _initialized = false; // Reset to database values
                              }
                              _isEditing = !_isEditing;
                            });
                          },
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'Not authenticated',
                style: TextStyle(color: AppColors.error),
              ),
            );
          }

          _populateUserData(user);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // 1. Profile Header & Avatar
                _buildProfileHeader(user),
                const SizedBox(height: 16),

                // 2. Emergency Highlights Banner (Blood Group & Conditions)
                _buildEmergencyBadge(),
                const SizedBox(height: 20),

                // 3. Personal & Demographic Info
                _buildSectionTitle('Personal & Identity Details', Icons.person_outline),
                const SizedBox(height: 10),
                _buildCardContainer([
                  _buildField('Full Legal Name', _nameController, enabled: _isEditing, icon: Icons.badge_outlined),
                  _buildReadOnlyField('Email Address', user.email, Icons.email_outlined),
                  _buildField('Phone Number', _phoneController, enabled: _isEditing, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                  _buildDateField('Date of Birth', _dobController, enabled: _isEditing),
                  _buildGenderDropdown(),
                  _buildField('Residential Address', _addressController, enabled: _isEditing, maxLines: 2, icon: Icons.home_outlined),
                ]),
                const SizedBox(height: 24),

                // 4. Clinical & Medical Record (Hospital Essential)
                _buildSectionTitle('Clinical & Medical Profile', Icons.medical_services_outlined),
                const SizedBox(height: 10),
                _buildCardContainer([
                  _buildBloodGroupDropdown(),
                  _buildField(
                    'Known Allergies',
                    _allergiesController,
                    hint: 'e.g. Penicillin, Peanuts, Sulfa, Latex (or None)',
                    enabled: _isEditing,
                    icon: Icons.warning_amber_rounded,
                  ),
                  _buildField(
                    'Chronic Medical Conditions',
                    _conditionsController,
                    hint: 'e.g. Diabetes, Hypertension, Asthma, Heart Disease',
                    enabled: _isEditing,
                    icon: Icons.healing_outlined,
                  ),
                  _buildField(
                    'Current Medications',
                    _medicationsController,
                    hint: 'e.g. Metformin 500mg, Aspirin 75mg',
                    enabled: _isEditing,
                    icon: Icons.medication_liquid_outlined,
                  ),
                ]),
                const SizedBox(height: 24),

                // 5. Emergency Contact (Next of Kin)
                _buildSectionTitle('Emergency Contact (Next of Kin)', Icons.contact_phone_outlined),
                const SizedBox(height: 10),
                _buildCardContainer([
                  _buildField('Emergency Contact Name', _emergencyNameController, enabled: _isEditing, icon: Icons.person_add_alt_1_outlined),
                  _buildField('Relationship', _emergencyRelationController, hint: 'e.g. Spouse, Father, Mother, Sibling', enabled: _isEditing, icon: Icons.group_outlined),
                  _buildField('Emergency Contact Phone', _emergencyPhoneController, enabled: _isEditing, icon: Icons.phone_in_talk_outlined, keyboardType: TextInputType.phone),
                ]),
                const SizedBox(height: 24),

                // Save Button (When in Edit Mode)
                if (_isEditing) ...[
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => _saveProfile(user),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text(
                        _isSaving ? 'Saving Changes...' : 'Save Profile',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 6. Account & Security Settings
                _buildSectionTitle('Account & Security Settings', Icons.settings_outlined),
                const SizedBox(height: 10),
                _buildSettingItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notification Preferences',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
                _buildSettingItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                ),
                _buildSettingItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
                ),
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: 'About MediLink',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutMedilinkScreen())),
                ),
                const SizedBox(height: 24),

                // Logout and Delete Account
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmLogout(),
                        icon: const Icon(Icons.logout, color: AppColors.primary, size: 18),
                        label: const Text('Log Out', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDeleteAccount(),
                        icon: const Icon(Icons.delete_forever, color: AppColors.error, size: 18),
                        label: const Text('Delete Account', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(
          child: Text('Error loading account: $error', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight.withOpacity(0.2),
                  border: Border.all(color: AppColors.primary, width: 2.5),
                ),
                child: ClipOval(
                  child: _photoBase64 != null && _photoBase64!.isNotEmpty
                      ? Image.memory(
                          base64Decode(_photoBase64!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 54, color: AppColors.primary),
                        )
                      : const Icon(Icons.person, size: 54, color: AppColors.primary),
                ),
              ),
              if (_isEditing)
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.displayName?.isNotEmpty == true ? user.displayName! : 'Patient User',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_information, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emergency Medical Tag',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedBloodGroup != null
                      ? 'Blood Group: $_selectedBloodGroup · ${_allergiesController.text.isNotEmpty ? 'Allergies: ${_allergiesController.text}' : 'No known allergies'}'
                      : 'Blood group not set. Edit profile to update.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    IconData? icon,
    int maxLines = 1,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint ?? label,
              prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.primary) : null,
              filled: true,
              fillColor: enabled ? Colors.white : AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderLight)),
              disabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.black12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textSecondaryLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller, {required bool enabled}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: enabled ? _selectDateOfBirth : null,
            child: IgnorePointer(
              ignoring: true,
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'DD/MM/YYYY',
                  prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primary),
                  suffixIcon: enabled ? const Icon(Icons.edit_calendar, size: 18) : null,
                  filled: true,
                  fillColor: enabled ? Colors.white : AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderLight)),
                  disabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.black12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodGroupDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Blood Group',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedBloodGroup != null && _bloodGroups.contains(_selectedBloodGroup) ? _selectedBloodGroup : null,
            items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
            onChanged: _isEditing ? (v) => setState(() => _selectedBloodGroup = v) : null,
            decoration: InputDecoration(
              hintText: 'Select Blood Group',
              prefixIcon: const Icon(Icons.bloodtype, size: 18, color: Colors.red),
              filled: true,
              fillColor: _isEditing ? Colors.white : AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderLight)),
              disabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.black12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gender',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedGender != null && _genders.contains(_selectedGender) ? _selectedGender : null,
            items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: _isEditing ? (v) => setState(() => _selectedGender = v) : null,
            decoration: InputDecoration(
              hintText: 'Select Gender',
              prefixIcon: const Icon(Icons.wc_outlined, size: 18, color: AppColors.primary),
              filled: true,
              fillColor: _isEditing ? Colors.white : AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderLight)),
              disabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.black12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 20),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondaryLight),
        onTap: onTap,
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of MediLink?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Warning: This will permanently delete your patient health profile and all active bookings. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).deleteAccount();
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}
