import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_theme.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/auth/repositories/user_profile_repository.dart';

/// Account Screen showing user profile and settings.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final UserProfileRepository _profileRepo = UserProfileRepository();
  bool _isEditing = false;

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController dobController;
  late TextEditingController addressController;
  late TextEditingController bloodGroupController;
  String? selectedGender;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    dobController = TextEditingController();
    addressController = TextEditingController();
    bloodGroupController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    dobController.dispose();
    addressController.dispose();
    bloodGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: Center(child: const Text('Not signed in')),
          );
        }

        // Load real user profile from Firebase
        final userProfileAsync = ref.watch(getUserProfileProvider(user.uid));

        return userProfileAsync.when(
          data: (profileUser) {
            final displayUser = profileUser ?? user;

            // Initialize controllers if empty (load from Firebase profile)
            if (nameController.text.isEmpty) {
              nameController.text = displayUser.displayName ?? '';
              emailController.text = displayUser.email;
              phoneController.text = displayUser.phoneNumber ?? '';
              dobController.text = displayUser.dateOfBirth ?? '';
              addressController.text = displayUser.address ?? '';
              bloodGroupController.text = displayUser.bloodGroup ?? '';
              selectedGender = displayUser.gender;
            }

            return Scaffold(
              backgroundColor: AppColors.surfaceLight,
              appBar: AppBar(
                backgroundColor: AppColors.cardLight,
                elevation: 1,
                title: Text(
                  'My Account',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: false,
                automaticallyImplyLeading: false,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: FilledButton.icon(
                        onPressed: _isEditing ? _saveProfile : () {
                          setState(() => _isEditing = true);
                        },
                        icon: Icon(_isEditing ? Icons.check : Icons.edit),
                        label: Text(_isEditing ? 'Save' : 'Edit'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _isEditing ? Colors.green : AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight, width: 1),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.account_circle,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isEditing)
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'Full Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            nameController.text.isNotEmpty ? nameController.text : 'User',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          emailController.text,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Edit Form
                  if (_isEditing) ...[
                    _buildEditField('Full Name', nameController),
                    _buildEditField('Email', emailController, enabled: false),
                    _buildEditField('Phone Number', phoneController),
                    _buildEditField('Date of Birth (DD/MM/YYYY)', dobController),
                    _buildGenderField(),
                    _buildEditField('Blood Group', bloodGroupController),
                    _buildEditField('Address', addressController, maxLines: 3),
                  ] else ...[
                    // View Profile
                    _buildProfileCard('Name', nameController.text.isNotEmpty ? nameController.text : '—'),
                    _buildProfileCard('Email', emailController.text),
                    _buildProfileCard('Phone', phoneController.text.isNotEmpty ? phoneController.text : '—'),
                    _buildProfileCard('Date of Birth', dobController.text.isNotEmpty ? dobController.text : '—'),
                    _buildProfileCard('Gender', selectedGender ?? '—'),
                    _buildProfileCard('Blood Group', bloodGroupController.text.isNotEmpty ? bloodGroupController.text : '—'),
                    _buildProfileCard('Address', addressController.text.isNotEmpty ? addressController.text : '—'),
                  ],
                ],
              ),
            );
          },
          loading: () => Scaffold(
            backgroundColor: AppColors.surfaceLight,
            appBar: AppBar(
              backgroundColor: AppColors.cardLight,
              elevation: 1,
              title: Text(
                'My Account',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: false,
              automaticallyImplyLeading: false,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, st) => Scaffold(
            backgroundColor: AppColors.surfaceLight,
            appBar: AppBar(
              backgroundColor: AppColors.cardLight,
              elevation: 1,
              title: Text(
                'My Account',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: false,
              automaticallyImplyLeading: false,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('Error loading profile: $err'),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller,
      {bool enabled = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: !enabled,
          fillColor: !enabled ? Colors.grey[100] : null,
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: selectedGender,
        decoration: InputDecoration(
          labelText: 'Gender',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: ['Male', 'Female', 'Other']
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (value) => setState(() => selectedGender = value),
      ),
    );
  }

  Widget _buildProfileCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    try {
      final authState = ref.read(authStateChangesProvider).value;
      if (authState == null) return;

      final updatedUser = authState.copyWith(
        displayName: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        dateOfBirth: dobController.text.trim(),
        gender: selectedGender,
        bloodGroup: bloodGroupController.text.trim(),
        address: addressController.text.trim(),
      );

      await _profileRepo.updateUserProfile(updatedUser);

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
