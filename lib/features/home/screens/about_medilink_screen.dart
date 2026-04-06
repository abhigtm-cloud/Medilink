import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';

/// About Medilink Screen
class AboutMedilinkScreen extends StatelessWidget {
  const AboutMedilinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 1,
        title: Text(
          'About Medilink',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo and app name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MEDILINK',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Healthcare at Your Fingertips',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Version info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Application', 'Medilink'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Version', '1.0.0'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Build', '1'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Platform', 'Android'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // About description
            Text(
              'About Medilink',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: Text(
                'Medilink is a comprehensive healthcare solution designed to connect patients with hospitals and healthcare professionals. Our mission is to make healthcare accessible, affordable, and convenient for everyone.\n\nWith Medilink, you can:\n• Browse and search hospitals near you\n• View doctor profiles and specializations\n• Book appointments easily\n• Manage your bookings\n• Receive instant notifications\n• Access healthcare information',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimaryLight,
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Key features
            Text(
              'Key Features',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.location_on_outlined,
              title: 'Hospital Locator',
              description: 'Find hospitals near you on an interactive map',
            ),
            _buildFeatureCard(
              icon: Icons.person_outline,
              title: 'Doctor Profiles',
              description: 'View doctor information and specializations',
            ),
            _buildFeatureCard(
              icon: Icons.event_note_outlined,
              title: 'Easy Booking',
              description: 'Book appointments in just a few taps',
            ),
            _buildFeatureCard(
              icon: Icons.notifications,
              title: 'Notifications',
              description: 'Get instant updates about your bookings',
            ),
            _buildFeatureCard(
              icon: Icons.verified_user_outlined,
              title: 'Secure',
              description: 'Your data is encrypted and protected',
            ),
            _buildFeatureCard(
              icon: Icons.support_agent_outlined,
              title: 'Support',
              description: '24/7 customer support available',
            ),
            const SizedBox(height: 24),
            // Team section
            Text(
              'Our Team',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            _buildTeamMember(
              name: 'Development Team',
              role: 'Building amazing healthcare solutions',
            ),
            _buildTeamMember(
              name: 'Customer Support',
              role: 'Always here to help you',
            ),
            const SizedBox(height: 24),
            // Acknowledgements
            Text(
              'Acknowledgements',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: Text(
                'Built with Flutter and Firebase\n\nSpecial thanks to our hospital partners and healthcare professionals who make this possible.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2025 Medilink',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All rights reserved',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember({required String name, required String role}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
